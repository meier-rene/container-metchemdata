######
# COCONUT filler script
######

# includes adding new entries and deleting non-existsing ones
# deletes entries only from substance table as references from other databases might still
# be present
# another function could delete entries from compund table that aren't referenced anymore
insert_coconut () {
 /usr/bin/psql -c "insert into library(library_name,library_id,last_updated,library_link) values ('coconut','8',date('1970-01-01'),'https://coconut.naturalproducts.net/');" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
 # check if database exists
 last_updated=$(/usr/bin/psql -c "SELECT last_updated FROM library where library_name='coconut';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 # get current modification date
 dbdatesecs=$(date -d $last_updated +%s)
 mostcurrentsecs=$dbdatesecs
 mostcurrent=""
 library_id=$(/usr/bin/psql -c "SELECT library_id FROM library where library_name='coconut';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 if [ ! -e /data/${COCONUT_MIRROR} ]
 then
   echo "/data/${COCONUT_MIRROR} not found"
   return 1
 fi

 # loop to check each data file
 unset IFS
 for i in $(ls /data/${COCONUT_MIRROR} | grep -e "csv.gz$")
 do
  echo "file ${i}"
  # check time stamp of file and database 
  filedatesecs=$(date -r /data/${COCONUT_MIRROR}/$i +%s)
  filedate=$(date -r /data/${COCONUT_MIRROR}/$i +%Y-%m-%d)
  if [ $filedatesecs -gt $mostcurrentsecs ]
  then
    mostcurrentsecs=$filedatesecs
    mostcurrent=$filedate
  fi  
  # get filename
  filename=$(echo $i | sed 's/\.csv\.gz//')
  # unzip file and make compatible with input format  
  gunzip -c -k /data/${COCONUT_MIRROR}/$i | grep -v 'InChI=none' > /tmp/${filename}.csv
  # write out values of specific columns
  # "coconut_id","molecular_formula","clean_smiles","inchi","inchikey"
  paste -d"|" \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"coconut_id$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"coconut_id$"?i:n;next}n{print "666"}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"molecular_formula$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"clean_smiles$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchi$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed 's/InChIKey=//' | tr '-' '|' ) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"coconut_id$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed 's/InChIKey=//' ) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"coconut_id$"?i:n;next}n{print "XXX"}' /tmp/${filename}.csv) \
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


