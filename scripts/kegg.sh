######
# kegg filler script
######

# depricated from substance table NOT from compound table
depricated_kegg_entries () {
 filename=$1
 library_id=$2
 if [ ! -e /tmp/${filename}.sql ]
 then
  echo "Error in depricated_kegg_entries(): /tmp/${filename}.sql not found. Nothing to delete."
  return 1
 fi
 # get accession ranges from filename
 IFS=' ' read -a ranges <<< "$(echo $filename | sed "s/.*_C0*\([0-9]*\)_C0*\([0-9]*\)/\1 \2/")"
 # get accessions not included anymore
 # this is performed by comparison 
 comm -23 <(for (( c=${ranges[0]}; c<=${ranges[1]}; c++ )); do echo 0000$c | sed "s/.*\(.....$\)/C\1/"; done | sort) <(cut -d"|" -f1 /tmp/${filename}.sql | sort) > /tmp/${filename}.depricated
 while read line
 do
   echo "depricated from substance where accession='${line}' and library_id='${library_id}';" >> /tmp/${filename}.depricated_query
 done < /tmp/${filename}.depricated
 rm /tmp/${filename}.depricated
 if [ -e /tmp/${filename}.depricated_query ] 
 then
   # execute query file onto postgres server
   /usr/bin/psql -f /tmp/${filename}.depricated_query -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null
   rm /tmp/${filename}.depricated_query
 fi
}


# includes adding new entries and deleting non-existsing ones
# deletes entries only from substance table as references from other databases might still
# be present
# another function could delete entries from compund table that aren't referenced anymore
insert_kegg () {
 /usr/bin/psql -c "insert into library(library_name,library_id,last_updated,library_link) values ('kegg','1',date('1970-01-01'),'http://www.kegg.jp');" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
 # check if database exists
 last_updated=$(/usr/bin/psql -c "SELECT last_updated FROM library where library_name='kegg';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 # get current modification date
 dbdatesecs=$(date -d $last_updated +%s)
 mostcurrentsecs=$dbdatesecs
 mostcurrent=""
 library_id=$(/usr/bin/psql -c "SELECT library_id FROM library where library_name='kegg';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 if [ ! -e /data/${KEGG_MIRROR} ]
 then
   echo "/data/${KEGG_MIRROR} not found"
   return 1       
 fi
 # loop to check each data file
 unset IFS
 for i in $(ls /data/${KEGG_MIRROR} | grep -e "gz$")
 do
  echo "file ${i}"
  # check time stamp of file and database 
  filedatesecs=$(date -r /data/${KEGG_MIRROR}/$i +%s)
  filedate=$(date -r /data/${KEGG_MIRROR}/$i +%Y-%m-%d)
  if [ $filedatesecs -gt $mostcurrentsecs ]
  then
      mostcurrentsecs=$filedatesecs
      mostcurrent=$filedate
  fi  
  # get filename
  filename=$(echo $i | sed 's/\.csv\.gz//')
  # unzip file
  gunzip -c -k /data/$KEGG_MIRROR/$i > /tmp/${filename}.csv
  # write out values of specific columns
  paste -d"|" \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"identifier$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"monoisotopicmass$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"molecularformula$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"smiles$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchi$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey1$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey2$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey3$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"name$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(paste -d"-" <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey1$"?i:n;next}n{print $n}' /tmp/${filename}.csv) <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey2$"?i:n;next}n{print $n}' /tmp/${filename}.csv) <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"inchikey3$"?i:n;next}n{print $n}' /tmp/${filename}.csv)) > /tmp/${filename}.sql
  # write all insert commands into one query file
  write_entries "/tmp/${filename}.sql" "${library_id}" > /dev/null
  # remove files
  rm /tmp/${filename}.sql
  rm /tmp/${filename}.csv
 done
 # update library modification date
 /usr/bin/psql -c "update library set last_updated='$mostcurrent' where library_id='$library_id';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
}
