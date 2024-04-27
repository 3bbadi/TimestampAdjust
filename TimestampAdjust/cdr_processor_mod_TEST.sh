#!/bin/bash
# cdr_processor_mod_TEST.sh
#BN-NGVS-1 /var/backup/vs/main/cdr/3bbadi

echo "starting script cdr_processor_mod_NS_V3.sh" >> /var/backup/vs/main/cdr/3bbadi/logs.log

cd /var/backup/vs/main/cdr/3bbadi/working

numberOfFiles=0
numberOfErrors=0

for f in *.json; do

actual_lines=$(wc -l <"$f")

  sed "s/$/,/g" "$f" > bkp_"$f"_bkp
  sed '$s/,$//' bkp_"$f"_bkp > bkp2_"$f"_bkp
  sed -e '1s/^/[/' -e 's/$/,/' -e '$s/,$/]/' bkp2_"$f"_bkp > bkp3_"$f"_bkp
  sed -i 's/,,/,/g' bkp3_"$f"_bkp
  cp -p bkp3_"$f"_bkp "$f"

  # send and move to archive
#  if scp "$f" ch_usr@10.230.191.66:/DataFiles/Enterprise/prepaid_files/Charging_Files/vs-files/vs-01; then
   if cp  "$f"  /tmp/3bbadi ; then
    echo "$f has been sent at $(date +'%Y-%m-%d %T')" >> /var/backup/vs/main/cdr/3bbadi/logs.log
    ((numberOfFiles++))
  else
    echo "Error: $f could not be sent at $(date +'%Y-%m-%d %T')" >> /var/backup/vs/main/cdr/3bbadi/logs.log
    ((numberOfErrors++))
  fi

  mv /var/backup/vs/main/cdr/3bbadi/working/"$f" /var/backup/vs/main/cdr/3bbadi/archive

  rm -f bkp_"$f"_bkp
  rm -f bkp2_"$f"_bkp
  rm -f bkp3_"$f"_bkp

  # Check if the file has the expected number of lines
  expected_lines=$(wc -l <"$f")
  
  if [ "$expected_lines" -ne "$actual_lines" ]; then
    echo "Error: $f has an unexpected number of lines (expected: $expected_lines, actual: $actual_lines)" >> /var/backup/vs/main/cdr/3bbadi/logs.log
    ((numberOfErrors++))
  fi

done

echo "$numberOfFiles files have been sent at $(date +'%Y-%m-%d %T')" >> /var/backup/vs/main/cdr/3bbadi/logs.log
echo "$numberOfErrors errors occurred during processing at $(date +'%Y-%m-%d %T')" >> /var/backup/vs/main/cdr/3bbadi/logs.log

# Compress all JSON files in the archive directory
gzip /var/backup/vs/main/cdr/3bbadi/archive/*.json

echo "finished cdr_processor_mod_NS_V5.sh script at $(date +'%Y-%m-%d %T')" >> /var/backup/vs/main/cdr/3bbadi/logs.log