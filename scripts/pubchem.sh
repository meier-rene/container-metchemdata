######
# pubchem filler script
######

# write a single pubchem entry as postgres query
write_pubchem_entry () {
 local line=$1
 local line=$(echo $line | sed "s/'/''/g")
 local outfolder=$2
 # read values from argument string
 IFS='|' read -a vals <<< "$line"
 if [ "${vals[1]}" == "" ]; then return 1; fi
 if [ "${vals[2]}" == "" ]; then return 1; fi
 if [ "${vals[3]}" == "" ]; then return 1; fi
 if [ "${vals[4]}" == "" ]; then return 1; fi
 if [ "${vals[5]}" == "" ]; then return 1; fi
 if [ "${vals[6]}" == "" ]; then return 1; fi
 folder=$(echo ${vals[5]} | sed "s/\(..\)/\1\//g")
 if [ ! -e $outfolder/compound/$folder ]; then mkdir -p $outfolder/compound/$folder; fi
 local inchikey="${vals[5]}-${vals[6]}"
 if [ "${vals[7]}" != "" ]; then inchikey="${vals[5]}-${vals[6]}-${vals[7]}"; fi
 # insert pubchem entry
 echo "${vals[1]}|${vals[2]}|${vals[3]}|${vals[4]}|${vals[5]}|${vals[6]}|${vals[7]}|${inchikey}|${vals[8]}|${vals[0]}" >> $outfolder/compound/${folder}/${inchikey}
}

write_pubchem_entries () {
 local file=$1
 local outfolder=$2
 local lastcompoundid=$3
 local library_id=$4
 local currentcompoundid=$lastcompoundid
 # compound table
 while read line
 do
  local line=$(echo $line | sed "s/'/''/g")
  IFS='|' read -a vals <<< "$line"
  if [ "${vals[1]}" == "" ]; then return 1; fi
  if [ "${vals[2]}" == "" ]; then return 1; fi
  if [ "${vals[3]}" == "" ]; then return 1; fi
  if [ "${vals[4]}" == "" ]; then return 1; fi
  if [ "${vals[5]}" == "" ]; then return 1; fi
  if [ "${vals[6]}" == "" ]; then return 1; fi
  currentcompoundid=$((currentcompoundid+1))
  echo ${currentcompoundid}|${vals[1]}|${vals[2]}|${vals[3]}|${vals[4]}|${vals[5]}|${vals[6]}|${vals[7]}|${inchikey}
 done < $file > $outfolder/compound.txt
 # substance table
 local currentcompoundid=$lastcompoundid
 while read line
 do
  local line=$(echo $line | sed "s/'/''/g")
  IFS='|' read -a vals <<< "$line"
  if [ "${vals[1]}" == "" ]; then return 1; fi
  if [ "${vals[2]}" == "" ]; then return 1; fi
  if [ "${vals[3]}" == "" ]; then return 1; fi
  if [ "${vals[4]}" == "" ]; then return 1; fi
  if [ "${vals[5]}" == "" ]; then return 1; fi
  if [ "${vals[6]}" == "" ]; then return 1; fi
  currentcompoundid=$((currentcompoundid+1))
  echo ${currentcompoundid}|$library_id|${currentcompoundid}|${vals[0]}
 done < $file > $outfolder/substance.txt
 # name table
 local currentcompoundid=$lastcompoundid
 while read line
 do
  local line=$(echo $line | sed "s/'/''/g")
  IFS='|' read -a vals <<< "$line"
  if [ "${vals[1]}" == "" ]; then return 1; fi
  if [ "${vals[2]}" == "" ]; then return 1; fi
  if [ "${vals[3]}" == "" ]; then return 1; fi
  if [ "${vals[4]}" == "" ]; then return 1; fi
  if [ "${vals[5]}" == "" ]; then return 1; fi
  if [ "${vals[6]}" == "" ]; then return 1; fi
  currentcompoundid=$((currentcompoundid+1))
  echo ${currentcompoundid}|${vals[8]}
 done < $file > $outfolder/name.txt
}


# deletes from substance table NOT from compound table
delete_pubchem_entries () {
 filename=$1
 library_id=$2
 if [ ! -e /tmp/${filename}.sql ]
 then
  echo "Error in delete_pubchem_entries(): /tmp/${filename}.sql not found. Nothing to delete."
  return 1
 fi
 # get accession ranges from filename
 IFS=' ' read -a ranges <<< "$(echo $filename | sed "s/.*_0*\([0-9]*\)_0*\([0-9]*\)/\1 \2/")"
 # get accessions not included anymore
 # this is performed by comparison 
 comm -23 <(for (( c=${ranges[0]}; c<=${ranges[1]}; c++ )); do echo $c; done | sort) <(cut -d"|" -f1 /tmp/${filename}.sql | sort) > /tmp/${filename}.delete
 while read line
 do
   echo "delete from substance where accession='${line}' and library_id='${library_id}';" >> /tmp/${filename}.delete_query
 done < /tmp/${filename}.delete
 rm /tmp/${filename}.delete
 if [ -e /tmp/${filename}.delete_query ] 
 then
   # execute query file onto postgres server
   /usr/bin/psql -f /tmp/${filename}.delete_query -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null
   rm /tmp/${filename}.delete_query
 fi
}

generate_pubchem_files() {
 echo "generate_pubchem_files"
 exists=$(/usr/bin/psql -c "select 1 from library where library_name='pubchem';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 if [ ! "$exists" == 1 ]
 then 
   echo "library pubchem does not exist"
   return 1
 fi
 library_id=$(/usr/bin/psql -c "SELECT library_id FROM library where library_name='pubchem';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 echo "library found -> $library_id"
 # check folders and clean
 echo "cleaning folders"
 if [ -e ${OUTPUT_FOLDER}/pubchem/compound/ ]; then rm -rf ${OUTPUT_FOLDER}/pubchem/compound; fi
 mkdir -p ${OUTPUT_FOLDER}/pubchem/compound/
 echo "downloading conversion tool"
 if [ ! -z ${PROXY+x} ]
 then
  wget -e use_proxy=yes -e http_proxy=$PROXY -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar
 else
  wget -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar
 fi
 # loop to check each data file
 if [ ! -e /data/${PUBCHEM_MIRROR} ]
 then
   echo "/data/${PUBCHEM_MIRROR} not found"
   exit 1       
 fi
 unset IFS
 for i in $(ls /data/${PUBCHEM_MIRROR} | grep -e "gz$")
 do
  echo "file $i"
  filename=$(echo $i | sed 's/\.sdf\.gz//')
  # unzip file
  gunzip -c -k /data/$PUBCHEM_MIRROR/$i > /tmp/${filename}.sdf
  # convert sdf to csv
  java -jar ~/ConvertSDF.jar sdf=/tmp/${filename}.sdf out=/tmp/ format=csv fast=true
  # write out values of specific columns
  paste -d"|" \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_COMPOUND_CID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_MONOISOTOPIC_WEIGHT$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_MOLECULAR_FORMULA$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_OPENEYE_CAN_SMILES$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_IUPAC_INCHI$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_IUPAC_INCHIKEY$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed "s/-/|/g") \
  <(awk -F '|' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_IUPAC_OPENEYE_NAME$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  > /tmp/${filename}.sql
  # write all insert commands into one query file
  IFS=''
  while read line
  do
   # writes single insert command to query file
   write_pubchem_entry "$line" "${OUTPUT_FOLDER}/pubchem/"
  done < /tmp/${filename}.sql
  # remove files
  rm /tmp/${filename}.sql
  rm /tmp/${filename}.sdf
 done
 if [ ! -e ${OUTPUT_FOLDER}/pubchem/compound ]; then return 1; fi
 # write database files
 compound_id=1
 substance_id=1
 if [ -e ${OUTPUT_FOLDER}/pubchem/compound.txt ]; then rm ${OUTPUT_FOLDER}/pubchem/compound.txt; fi
 if [ -e ${OUTPUT_FOLDER}/pubchem/substance.txt ]; then rm ${OUTPUT_FOLDER}/pubchem/substance.txt; fi
 if [ -e ${OUTPUT_FOLDER}/pubchem/name.txt ]; then rm ${OUTPUT_FOLDER}/pubchem/name.txt; fi
 # write file to import
 unset IFS
 for i in $(find ${OUTPUT_FOLDER}/pubchem/compound -type f)
 do
  inserted=0
  key=$(echo $i | sed "s/.*\///")
  folder=$(echo $key | sed "s/\(..\)/\1\//g")
  number_lines=$(wc -l $i | cut -d" " -f1)
  for (( num=1; num<=$number_lines; num++ ))
  do
    line=$(sed -n "${num}p" ${OUTPUT_FOLDER}/pubchem/compound/${folder}/$key)
    compound_line=$(echo $line | cut -d"|" -f1-8)
    name_line=$(echo $line | cut -d"|" -f9)
    substance_line=$(echo $line | cut -d"|" -f10)
    if [ "$inserted" -eq "0" ]
    then
      echo "${compound_id}|$compound_line" >> ${OUTPUT_FOLDER}/pubchem/compound.txt
      echo "${name_line}|${substance_id}" >> ${OUTPUT_FOLDER}/pubchem/name.txt
      echo "${substance_id}|${library_id}|${compound_id}|${substance_line}" >> ${OUTPUT_FOLDER}/pubchem/substance.txt
      inserted=1
      substance_id=$((substance_id+1))
    else
      echo "${name_line}|${substance_id}" >> ${OUTPUT_FOLDER}/pubchem/name.txt
      echo "${substance_id}|${library_id}|${compound_id}|${substance_line}" >> ${OUTPUT_FOLDER}/pubchem/substance.txt
      substance_id=$((substance_id+1))
    fi
  done
  compound_id=$((compound_id+1))
  # delete processed file
 done
 # insert data into database
 echo "copy data into tables"
 /usr/bin/psql -c "\COPY compound FROM '${OUTPUT_FOLDER}/pubchem/compound.txt' ( FORMAT CSV, DELIMITER('|') );" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
 /usr/bin/psql -c "\COPY substance FROM '${OUTPUT_FOLDER}/pubchem/substance.txt' ( FORMAT CSV, DELIMITER('|') );" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
 /usr/bin/psql -c "\COPY name FROM '${OUTPUT_FOLDER}/pubchem/name.txt' ( FORMAT CSV, DELIMITER('|') );" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
}

# includes adding new entries and deleting non-existsing ones
# deletes entries only from substance table as references from other databases might still
# be present
# another function could delete entries from compund table that aren't referenced anymore
update_pubchem () {
 # check if database exists
 exists=$(/usr/bin/psql -c "select 1 from library where library_name='pubchem';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 last_updated=$(/usr/bin/psql -c "SELECT last_updated FROM library where library_name='pubchem';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 # get current modification date
 dbdatesecs=$(date -d $last_updated +%s)
 mostcurrentsecs=$dbdatesecs
 mostcurrent=""
 if [ ! "$exists" == 1 ]
 then 
   echo "library pubchem does not exist"
   return 1
 fi
 library_id=$(/usr/bin/psql -c "SELECT library_id FROM library where library_name='pubchem';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 # download sdf csv conversion tool
 wget -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar
 # loop to check each data file
 if [ ! -e /data/${PUBCHEM_MIRROR} ]
 then
   echo "/data/${PUBCHEM_MIRROR} not found"
   exit 1       
 fi
 unset IFS
 for i in $(ls /data/${PUBCHEM_MIRROR} | grep -e "gz$")
 do
  echo "file $i"
  # check time stamp of file and database 
  filedatesecs=$(date -r /data/${PUBCHEM_MIRROR}/$i +%s)
  filedate=$(date -r /data/${PUBCHEM_MIRROR}/$i +%Y-%m-%d)
  if [ $dbdatesecs -ge $filedatesecs ]
  then
      break
  fi  
  if [ $filedatesecs -gt $mostcurrentsecs ]
  then
      mostcurrentsecs=$filedatesecs
      mostcurrent=$filedate
  fi  
  # get filename
  filename=$(echo $i | sed 's/\.sdf\.gz//')
  # unzip file
  gunzip -c -k /data/$PUBCHEM_MIRROR/$i > /tmp/${filename}.sdf
  # convert sdf to csv
  java -jar ~/ConvertSDF.jar sdf=/tmp/${filename}.sdf out=/tmp/ format=csv
  # rm unzipped sdf
  rm /tmp/${filename}.sdf
  # write out values of specific columns
  paste -d"|" \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_COMPOUND_CID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_MONOISOTOPIC_WEIGHT$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_MOLECULAR_FORMULA$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_OPENEYE_CAN_SMILES$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_IUPAC_INCHI$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_IUPAC_INCHIKEY$"?i:n;next}n{print $n}' /tmp/${filename}.csv | sed "s/-/|/g") \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"PUBCHEM_IUPAC_OPENEYE_NAME$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  > /tmp/${filename}.sql
  # write all insert commands into one query file
  IFS=''
  while read line
  do
   # writes single insert command to query file
   write_pubchem_entry "$line" "$library_id" "/tmp/${filename}.insert_query"
  done < /tmp/${filename}.sql
  # check if insert query file was generated
  if [ -e /tmp/${filename}.insert_query ] 
  then
    # execute query file onto postgres server
    /usr/bin/psql -f /tmp/${filename}.insert_query -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null
    rm /tmp/${filename}.insert_query
  fi
  # delete non reference entries
  delete_pubchem_entries $filename $library_id
  rm /tmp/${filename}.sql
  rm /tmp/${filename}.csv
 done
 # update library modification date
 /usr/bin/psql -c "update library set last_updated='$mostcurrent' where library_id='$library_id';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
}
