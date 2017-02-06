######
# hmdb filler script
######

insert_hmdb() {
 /usr/bin/psql -c "insert into library(library_name,library_id,last_updated,library_link) values ('hmdb','6',date('1970-01-01'),'http://www.hmdb.ca/metabolites/');" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
 library_id=$(/usr/bin/psql -c "SELECT library_id FROM library where library_name='hmdb';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 last_updated=$(/usr/bin/psql -c "SELECT last_updated FROM library where library_name='hmdb';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 dbdatesecs=$(date -d $last_updated +%s)
 mostcurrentsecs=$dbdatesecs
 mostcurrent=""
 echo "library found -> $library_id"
 echo "downloading conversion tool"
 if [ ! -z ${PROXY+x} ]
 then
  wget -e use_proxy=yes -e http_proxy=$PROXY -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar
 else
  wget -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar
 fi
 # loop to check each data file
 if [ ! -e /data/${HMDB_MIRROR} ]
 then
   echo "/data/${HMDB_MIRROR} not found"
   exit 1       
 fi
 unset IFS
 for i in $(ls /data/${HMDB_MIRROR} | grep -e "tgz$")
 do
  echo "file ${i}"
  filedatesecs=$(date -r /data/${HMDB_MIRROR}/$i +%s)
  filedate=$(date -r /data/${HMDB_MIRROR}/$i +%Y-%m-%d)
  if [ $filedatesecs -gt $mostcurrentsecs ]
  then
    mostcurrentsecs=$filedatesecs
    mostcurrent=$filedate
  fi  
  filename=$(echo $i | sed 's/\.sdf\.tgz//')
  # unzip file
  gunzip -c -k /data/$HMDB_MIRROR/$i > /tmp/${filename}.sdf
  # convert sdf to csv
  java -jar ~/ConvertSDF.jar sdf=/tmp/${filename}.sdf out=/tmp/ format=csv fast=true skipEntry=EXACT_MASS,INCHI_IDENTIFIER,INCHI_KEY,FORMULA,SMILES
  # write out values of specific columns
  paste -d"|" \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"DATABASE_ID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"EXACT_MASS$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"FORMULA$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"SMILES$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"INCHI_IDENTIFIER$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"INCHI_KEY$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed "s/-/|/g") \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"GENERIC_NAME$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"INCHI_KEY$"?i:n;next}n{print $n}' /tmp/${filename}.csv) > /tmp/${filename}.sql
  # writes single insert command to query file
  write_entries "/tmp/${filename}.sql" "${library_id}" > /dev/null
  # remove files
  rm /tmp/${filename}.sql
  rm /tmp/${filename}.sdf
  rm /tmp/${filename}.csv
 done
 # update library modification date
 /usr/bin/psql -c "update library set last_updated='$mostcurrent' where library_id='$library_id';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
}

update_hmdb() {
 last_updated=$(/usr/bin/psql -c "SELECT last_updated FROM library where library_name='hmdb';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 dbdatesecs=$(date -d $last_updated +%s)
 mostcurrentsecs=$dbdatesecs
 mostcurrent=""
 # loop to check each data file
 if [ ! -e /data/${HMDB_MIRROR} ]
 then
   echo "/data/${HMDB_MIRROR} not found"
   exit 1       
 fi
 echo "library found -> $library_id"
 # check folders and clean
 echo "cleaning folders"
 echo "downloading conversion tool"
 if [ ! -z ${PROXY+x} ]
 then
  wget -e use_proxy=yes -e http_proxy=$PROXY -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar
 else
  wget -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar
 fi
 for i in $(ls /data/${HMDB_MIRROR} | grep -e "tgz$")
 do
  echo "file ${i}"
  filedatesecs=$(date -r /data/${HMDB_MIRROR}/$i +%s)
  filedate=$(date -r /data/${HMDB_MIRROR}/$i +%Y-%m-%d)
  if [ $dbdatesecs -ge $filedatesecs ]
  then
    break
  fi
  if [ $filedatesecs -gt $mostcurrentsecs ]
  then
    mostcurrentsecs=$filedatesecs
    mostcurrent=$filedate
  fi  
  filename=$(echo $i | sed 's/\.sdf\.tgz//')
  # unzip file
  gunzip -c -k /data/$HMDB_MIRROR/$i > /tmp/${filename}.sdf
  # convert sdf to csv
  java -jar ~/ConvertSDF.jar sdf=/tmp/${filename}.sdf out=/tmp/ format=csv fast=true skipEntry=EXACT_MASS,INCHI_IDENTIFIER,INCHI_KEY,FORMULA,SMILES
  # write out values of specific columns
  paste -d"|" \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"DATABASE_ID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"EXACT_MASS$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"FORMULA$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"SMILES$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"INCHI_IDENTIFIER$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"INCHI_KEY$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed "s/-/|/g") \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"GENERIC_NAME$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"INCHI_KEY$"?i:n;next}n{print $n}' /tmp/${filename}.csv) > /tmp/${filename}.sql
  write_entries "/tmp/${filename}.sql" "${library_id}" > /dev/null
  # remove files
  rm /tmp/${filename}.sql
  rm /tmp/${filename}.sdf
  rm /tmp/${filename}.csv
 done
 remove_duplicates
 # update library modification date
 /usr/bin/psql -c "update library set last_updated='$mostcurrent' where library_id='$library_id';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
}
