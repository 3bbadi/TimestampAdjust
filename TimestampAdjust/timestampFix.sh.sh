#!/bin/bash
# ScriptName: timestampFix.sh

# Load environment variables from .env file
set -o allexport
source .env
set +o allexport

echo "
#####################################################################
script   timestampFixV5.sh   started at $(date +'%Y-%m-%d %T')
#####################################################################
" >> "$LOG_FILE"

cd "$SOURCE_DIRECTORY"

# Copy files from temporary directory to raw_backup
for ((i=0; i<=5; i++)); do
    cp -p "/tmp/VSCDR/VSCDR_0001_*$(date --date="${i} days ago" +%Y%m%d)*.json" "$SOURCE_DIRECTORY/raw_backup"
done

numberOfFiles=0

# Move files from temporary directory to source_directory
mv /tmp/VSCDR/* "$SOURCE_DIRECTORY"

cd "$SOURCE_DIRECTORY/working"

# Loop through each .json file in the current directory
for filename in *.json; do
    # Extract the timestamp from the filename
    timestamp=$(echo "$filename" | sed 's/^.*_\([0-9]\{8\}-[0-9]\{6\}\)\.json$/\1/')
    
    # Reformat the timestamp for the date command
    reformatted_timestamp=$(date -d "$timestamp" +"%Y-%m-%d %H:%M:%S")
    
    # Calculate new timestamp by adding 1 hour
    new_timestamp=$(date -d "$reformatted_timestamp + 1 hour" +"%Y%m%d-%H%M%S")
    
    # Replace the timestamp in the filename
    new_filename=$(echo "$filename" | sed "s/\([0-9]\{8\}-[0-9]\{6\}\)\.json/$new_timestamp.json/")
    
    # Rename the file
    mv "$filename" "$new_filename"
    
    echo "$filename file name changed to $new_filename" >> "$LOG_FILE"
    
    ((numberOfFiles++))
done

echo "
##### Processed $numberOfFiles files at $(date +'%Y-%m-%d %T'). ####
" >> "$LOG_FILE"

###########################################################
###### Change timestamps inside each .json file ###########
###########################################################
echo "### Start changing files timestamps ###" >> "$LOG_FILE"

numberOfFiles=0

# Loop over all .json files in the current directory
for input_file in *.json; do
    # Create a temporary file to store modified data
    temp_file=$(mktemp)

    # Process each line of the input file
    while IFS= read -r line; do
        # Check if the line contains a timestamp
        if [[ "$line" =~ @timestamp\":\"([0-9]{8}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4}) ]]; then
            timestamp_str="${BASH_REMATCH[1]}"
            updated_timestamp_str=$(date -d "${timestamp_str:0:8} ${timestamp_str:9:2}:${timestamp_str:12:2}:${timestamp_str:15:2} + 1 hour" +"%Y%m%dT%H:%M:%S%z" | sed 's/:\([0-9][0-9]\)$/\1/')
            updated_line="${line//@timestamp\":\"$timestamp_str/@timestamp\":\"$updated_timestamp_str}"
            echo "$updated_line" >> "$temp_file"
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$input_file"

    # Overwrite the input file with modified data
    mv "$temp_file" "$input_file"

    ((numberOfFiles++))
done

echo "##### $numberOfFiles files had their timestamps changed at $(date +'%Y-%m-%d %T'). ####" >> "$LOG_FILE"

# Run cdr_processor_mod_TEST.sh in silent mode
/var/backup/vs/main/cdr/3bbadi/cdr_processor_mod_TEST.sh >> /dev/null
