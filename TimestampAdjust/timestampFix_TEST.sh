#!/bin/bash
#timestampFix_TEST.sh 
#BN-NGVS-1 /var/backup/vs/main/cdr/3bbadi



echo "

#####################################################################
script   timestampFixV5.sh   started at $(date +'%Y-%m-%d %T')
#####################################################################
" >> /var/backup/vs/main/cdr/3bbadi/logs.log


cd /var/backup/vs/main/cdr/3bbadi


# take raw_backup  #XXXX edit
cp -p /tmp/VSCDR/VSCDR_0001_*`date --date="0 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/raw_backup
cp -p /tmp/VSCDR/VSCDR_0001_*`date --date="1 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/raw_backup
cp -p /tmp/VSCDR/VSCDR_0001_*`date --date="2 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/raw_backup
cp -p /tmp/VSCDR/VSCDR_0001_*`date --date="3 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/raw_backup
cp -p /tmp/VSCDR/VSCDR_0001_*`date --date="4 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/raw_backup
cp -p /tmp/VSCDR/VSCDR_0001_*`date --date="5 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/raw_backup

numberOfFiles=0

#get copy of all .json file from oraginal path /cdr >> test/3bbadi to test



####################
#to chech that files recived correctly from C5-NGVS
####################
###
mv /tmp/VSCDR/* /var/backup/vs/main/cdr/3bbadi
###
# Path to the directory containing the files you want to check
target_directory="/var/backup/vs/main/cdr/3bbadi"

# Read each line of file_counts.txt
while IFS= read -r line; do
    # Skip the header line
    if $skip_header; then
        if [[ "$line" == "File Counts and Line Counts:" ]]; then
            skip_header=false
        fi
        continue
    fi
    
    # Check if we reached the footer
    if [[ "$line" == "Total Files Sent: "* ]]; then
        total_files_sent=$(echo "$line" | cut -d' ' -f4)
        break
    fi
    
    # Extract filename and line count from the line using awk
    filename=$(echo "$line" | awk -F ', ' '{print $1}' | cut -d' ' -f2)
    expected_lines=$(echo "$line" | awk -F ', ' '{print $2}' | cut -d' ' -f2)

    # Check if the file exists in the target directory
    if [ -f "$target_directory/$filename" ]; then
        # Get the actual line count of the file
        actual_lines=$(wc -l < "$target_directory/$filename")
        
        # Compare actual line count with expected line count
        if [ "$actual_lines" -eq "$expected_lines" ]; then
            echo "File $filename exists and has correct line count: $expected_lines"  >> /var/backup/vs/main/cdr/3bbadi/logs.log
        else
            echo "Error: File $filename exists but has incorrect line count!"  >> /var/backup/vs/main/cdr/3bbadi/logs.log
        fi
    else
        echo "Error: File $filename does not exist!"  >> /var/backup/vs/main/cdr/3bbadi/logs.log
    fi
done < "file_counts.txt"

echo "Total files processed: $total_files_sent
"  >> /var/backup/vs/main/cdr/3bbadi/logs.log






#move them to /working
mv /var/backup/vs/main/cdr/3bbadi/VSCDR_0001_*`date --date="0 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/working 
mv /var/backup/vs/main/cdr/3bbadi/VSCDR_0001_*`date --date="1 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/working 
mv /var/backup/vs/main/cdr/3bbadi/VSCDR_0001_*`date --date="2 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/working
mv /var/backup/vs/main/cdr/3bbadi/VSCDR_0001_*`date --date="3 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/working
mv /var/backup/vs/main/cdr/3bbadi/VSCDR_0001_*`date --date="4 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/working
mv /var/backup/vs/main/cdr/3bbadi/VSCDR_0001_*`date --date="5 days ago" +"%Y%m%d"`*.json /var/backup/vs/main/cdr/3bbadi/working





cd /var/backup/vs/main/cdr/3bbadi/working

# loop through all the .json files in the current directory
for filename in *.json; do

  # extract the timestamp portion of the filename
  timestamp=$(echo $filename | sed 's/^.*_\([0-9]\{8\}-[0-9]\{6\}\)\.json$/\1/')

  # reformat the timestamp for the date command
  reformatted_timestamp=$(echo "$timestamp" | sed 's/\(....\)\(..\)\(..\)-\(..\)\(..\)\(..\)/\1-\2-\3 \4:\5:\6/')

  # convert the timestamp to a Unix timestamp
  unix_timestamp=$(date -d "$reformatted_timestamp" +%s)

  # add 1 hour to the Unix timestamp
  unix_timestamp=$((unix_timestamp + 3600))

  # convert the Unix timestamp back to a timestamp string
  new_timestamp=$(date -d "@$unix_timestamp" "+%Y%m%d-%H%M%S")

  # replace the old timestamp with the new timestamp in the filename


  new_filename=$(echo "$filename" | sed "s/\([0-9]\{8\}-[0-9]\{6\}\)\.json/$new_timestamp.json/")


mv "$filename" "$new_filename"

echo "$filename" 'file name  changed to ' "$new_filename" >> /var/backup/vs/main/cdr/3bbadi/logs.log

((numberOfFiles++))


done

echo "
##### Processed " "$numberOfFiles" " files at $(date +"%Y-%m-%d %T"). ####
" >> /var/backup/vs/main/cdr/3bbadi/logs.log

###########################################################
######change timestamp inside each .json file #############
###########################################################
echo "###       start changing files timestamps       ###" >> /var/backup/vs/main/cdr/3bbadi/logs.log

numberOfFiles=0

#Loop over all files with the .json extension in the current directory
for input_file in *.json; do

#filecount_ex=$(wc -l "$input_file")
filecount_ex=$(wc -l < "$input_file" | awk '{print $1}')


# Skip files that contain ".out" in the name

# Create a temporary file to store the modified data for each line
temp_file=$(mktemp)

# Read the file data line by line and process each line separately
while IFS= read -r line; do
    # Check if the line contains a timestamp
        if [[ "$line" =~ @timestamp\":\"([0-9]{8}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4}) ]]; then
        # Extract the timestamp string
        timestamp_str="${BASH_REMATCH[1]}"

            # Convert to Unix timestamp
            unix_timestamp=$(date -d "${timestamp_str:0:8} ${timestamp_str:9:2}:${timestamp_str:12:2}:${timestamp_str:15:2}" +"%s")

            # Add 1 hour to the Unix timestamp
            updated_unix_timestamp=$((unix_timestamp + 3600))

            # Convert back to timestamp string
                        updated_timestamp_str=$(date -d @"${updated_unix_timestamp}" +"%Y%m%dT%H:%M:%S%z" | sed 's/:\([0-9][0-9]\)$/\1/')

            # Replace the original timestamp with the updated timestamp in the line
            updated_line="${line//@timestamp\":\"$timestamp_str/@timestamp\":\"$updated_timestamp_str}"

            # Write the updated line to the temporary file
            echo "$updated_line" >> "$temp_file"

        else
            # If the line doesn't contain a timestamp, write it to the temporary file as-is
            echo "$line" >> "$temp_file"
        fi

    done < "$input_file"

#filecount=$(wc -l "$temp_file")
filecount=$(wc -l < "$temp_file" | awk '{print $1}')


    # Overwrite the input file with the modified data from the temporary file
    mv "$temp_file" "$input_file"


#if [[ $filecount -eq $filecount_ex ]]; then
#
#        echo "files " "$input_file" " had changed timestamp " >> /var/backup/vs/main/cdr/3bbadi/logs.log
#
#else
#        echo "Error: file " '$input_file' "count mismatch (before: $filecount_ex, after: $filecount)"
#
#fi

if [[ $filecount -eq $filecount_ex ]]; then
    echo "Files $input_file had their timestamps changed." >> /var/backup/vs/main/cdr/3bbadi/logs.log
else
    echo "Error: File '$input_file' count mismatch (before: $filecount_ex, after: $filecount)" >> /var/backup/vs/main/cdr/3bbadi/logs.log
fi



((numberOfFiles++))



done

echo "#####  " "$numberOfFiles" "files had changed timestamp at $(date +'%Y-%m-%d %T'). ####" >> /var/backup/vs/main/cdr/3bbadi/logs.log


/var/backup/vs/main/cdr/3bbadi/cdr_processor_mod_TEST.sh >> /dev/null