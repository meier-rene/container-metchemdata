######
# swisslipids filler script
######

# includes adding new entries and deleting non-existsing ones
# deletes entries only from substance table as references from other databases might still
# be present
# another function could delete entries from compund table that aren't referenced anymore
insert_swisslipids () {
 /usr/bin/psql -c "insert into library(library_name,library_id,last_updated,library_link) values ('swisslipids','7',date('1970-01-01'),'https://www.swisslipids.org/');" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
 # check if database exists
 last_updated=$(/usr/bin/psql -c "SELECT last_updated FROM library where library_name='swisslipids';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 # get current modification date
 dbdatesecs=$(date -d ${last_updated} +%s)
 mostcurrentsecs=$dbdatesecs
# mostcurrent="" ## 
 library_id=$(/usr/bin/psql -c "SELECT library_id FROM library where library_name='swisslipids';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 if [ ! -e /data/${SWISSLIPIDS_MIRROR} ]
 then
   echo "/data/${SWISSLIPIDS_MIRROR} not found"
   return 1
 fi
 # loop to check each data file
 unset IFS
 for i in $(ls /data/${SWISSLIPIDS_MIRROR} | grep -e "gz$")
 do
  echo "file ${i}"
  # check time stamp of file and database 
  filedatesecs=$(date -r /data/${SWISSLIPIDS_MIRROR}/$i +%s)
  filedate=$(date -r /data/${SWISSLIPIDS_MIRROR}/$i +%Y-%m-%d)
  if [ $filedatesecs -gt $mostcurrentsecs ]
  then
    mostcurrentsecs=$filedatesecs
    mostcurrent=$filedate
  fi  
  # get filename
  filename=$(echo $i | sed 's/\.csv\.gz//')
  # unzip file and make compatible with input format  
  gunzip -c -k /data/${SWISSLIPIDS_MIRROR}/$i | grep -v 'InChI=none' > /tmp/${filename}.csv
  # write out values of specific columns
  paste -d"|" \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"Lipid ID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"Exact Mass \(neutral form\)$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"Formula \(pH7.3\)$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"SMILES \(pH7.3\)$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"InChI \(pH7.3\)$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"InChI key \(pH7.3\)$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed 's/InChIKey=//' | tr '-' '|' ) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"Lipid ID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"InChI key \(pH7.3\)$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed 's/InChIKey=//' ) \
  <(awk -F '[\t]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"Name$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  | grep -v '||' \
  > /tmp/${filename}.sql

  # write all insert commands into one query file
  write_entries "/tmp/${filename}.sql" "${library_id}" > /dev/null
  # remove files
#  rm /tmp/${filename}.sql
#  rm /tmp/${filename}.csv
 done
 # update library modification date
 /usr/bin/psql -c "update library set last_updated='$mostcurrent' where library_id='$library_id';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
}
