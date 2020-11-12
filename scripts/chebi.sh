######
# chebi filler script
######

# includes adding new entries and deleting non-existsing ones
# deletes entries only from substance table as references from other databases might still
# be present
# another function could delete entries from compund table that aren't referenced anymore
insert_chebi () {
 /usr/bin/psql -c "insert into library(library_name,library_id,last_updated,library_link) values ('chebi','3',date('1970-01-01'),'https://www.ebi.ac.uk/chebi');" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
 # check if database exists
 last_updated=$(/usr/bin/psql -c "SELECT last_updated FROM library where library_name='chebi';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 # get current modification date
 dbdatesecs=$(date -d $last_updated +%s)
 mostcurrentsecs=$dbdatesecs
 mostcurrent=""
 library_id=$(/usr/bin/psql -c "SELECT library_id FROM library where library_name='chebi';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 if [ ! -e /data/${CHEBI_MIRROR} ]
 then
   echo "/data/${CHEBI_MIRROR} not found"
   return 1
 fi
 # loop to check each data file
 unset IFS
 for i in $(ls /data/${CHEBI_MIRROR} | grep -e ".sdf.gz$")
 do
  echo "file ${i}"
  # check time stamp of file and database 
  filedatesecs=$(date -r /data/${CHEBI_MIRROR}/$i +%s)
  filedate=$(date -r /data/${CHEBI_MIRROR}/$i +%Y-%m-%d)
  if [ $filedatesecs -gt $mostcurrentsecs ]
  then
    mostcurrentsecs=$filedatesecs
    mostcurrent=$filedate
  fi  
  # get filename
  filename=$(echo $i | sed 's/\.sdf\.gz//')
  # unzip file, turn SDF into key-value

  zcat /data/${CHEBI_MIRROR}/$i |\
      grep -A 1 '^> <' |\
      sed -e 's/^> <\(.*\)>$/\1/' |\
      grep -v "^--$" |\
      sed '$!N;s/\n/\t/' |\
      egrep '(^ChEBI ID[[:space:]])|(^Mass[[:space:]])|(^Formulae[[:space:]])|(^SMILES[[:space:]])|(^InChI[[:space:]])|(^InChIKey[[:space:]])|(^ChEBI Name[[:space:]])' |\
      sed -e 's/^ChEBI ID/\nChEBI ID/' > /tmp/${filename}.keys

  echo "ChEBI ID|Mass|Formulae|SMILES|InChI|InChIKey|ChEBI Name" > /tmp/${filename}.csv
  awk -v OFS='|' '
    match($0, /\t/) {a[substr($0,1,RSTART-1)] = substr($0,RSTART+RLENGTH)}
    /^$/ {print a["ChEBI ID"], a["Mass"], a["Formulae"], a["SMILES"], a["InChI"], a["InChIKey"], a["ChEBI Name"]; split("", a)}
    END {print a["ChEBI ID"], a["Mass"], a["Formulae"], a["SMILES"], a["InChI"], a["InChIKey"], a["ChEBI Name"]}
' /tmp/${filename}.keys >> /tmp/${filename}.csv
  # write out values of specific columns
  # Input order: "ChEBI ID|Mass|Formulae|SMILES|InChI|InChIKey|ChEBI Name" 
  paste -d"|" \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"ChEBI ID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"Mass$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"Formulae$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"SMILES$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"InChI$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"InChIKey$"?i:n;next}n{print $n}' /tmp/${filename}.csv | tr '-' '|' ) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"ChEBI ID$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"InChIKey$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  <(awk -F '[|]' -v c="" 'NR==1{for(i=1;i<=NF;i++)n=$i~"ChEBI Name$"?i:n;next}n{print $n}' /tmp/${filename}.csv) \
  | grep -v '||' > /tmp/${filename}.sql

  # write all insert commands into one query file
  write_entries "/tmp/${filename}.sql" "${library_id}" > /dev/null
  # remove files
  rm /tmp/${filename}.sql
  rm /tmp/${filename}.csv
 done
 # update library modification date
 /usr/bin/psql -c "update library set last_updated='$mostcurrent' where library_id='$library_id';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
}
