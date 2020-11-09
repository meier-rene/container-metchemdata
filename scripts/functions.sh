
################
# functions
################

check_database_exists () {
 psql -lqt -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB | cut -d \| -f 1 | grep -c $POSTGRES_DB
}

# check whether log folder is set and creates subfolders
check_log_folder () {
 type=$1
 # check whether log folder is set
 if [ ! -z ${LOG_FOLDER+x} ]
 then
  # check whether folder already exists and delete
  if [ -e $LOG_FOLDER/$type ]
  then
   rm -rf $LOG_FOLDER/$type 
  fi 
  # create new log folder for current type
  mkdir $LOG_FOLDER/$type
 fi
}

# check whether read-only database user exists and creats if not
check_database_user () {
 # retrieve 1 if user exists
 user_exists=$(/usr/bin/psql -c "SELECT 1 FROM pg_roles WHERE rolname='metchemro'" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 if [ ! "${user_exists}" == "1" ]; then
  password='metchemro'
  if [ ! "${METCHEMRO_PASSWORD}" == "" ]
  then
   password=${METCHEMRO_PASSWORD}
  fi
  /usr/bin/psql -c "CREATE USER metchemro with password '$password';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
  /usr/bin/psql -c "GRANT SELECT ON compound TO metchemro;" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
  /usr/bin/psql -c "GRANT SELECT ON substance TO metchemro;" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
  /usr/bin/psql -c "GRANT SELECT ON name TO metchemro;" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
  /usr/bin/psql -c "GRANT SELECT ON library TO metchemro;" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
 fi
}


write_entries () {
 local file=$1
 local library_id=$2
 currentcompoundid=$(/usr/bin/psql -c "SELECT max(compound_id) FROM compound;" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB)
 if [ "$currentcompoundid" == "" ]; then currentcompoundid=1; else currentcompoundid=$((currentcompoundid+1)); fi
 
 numlines=$(wc -l $file | cut -d" " -f1)
 # compound table
 paste -d"|" <(seq $currentcompoundid 1 $(expr $numlines + $currentcompoundid - 1)) <(cut -d"|" -f2,3,4,5,6,7,8,10 $file) | /usr/bin/psql -c "\COPY compound FROM STDIN ( FORMAT CSV, DELIMITER('|') );" -h  $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB

 # substance table
 paste -d"|" <(seq $currentcompoundid 1 $(expr $numlines + $currentcompoundid - 1)) <(echo $(yes $library_id | head -n${numlines}) | tr ' ' '\n') <(seq $currentcompoundid 1 $(expr $numlines + $currentcompoundid - 1)) <(cut -d"|" -f1 $file) | /usr/bin/psql -c "\COPY substance FROM STDIN ( FORMAT CSV, DELIMITER('|') );" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB

 # name table
 paste -d"|" <(cut -d"|" -f9 $file | sed "s/\"//g" | sed "s/'/''/g") <(seq $currentcompoundid 1 $(expr $numlines + $currentcompoundid - 1)) | /usr/bin/psql -c "\COPY name FROM STDIN ( FORMAT CSV, DELIMITER('|') );" -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB
}


# init database and create tables
# initial run needed to do once
# !!! deletes all tables in the database first !!!
init_database () {
 /usr/bin/psql -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB < /schema/MetChemSchema.sql
 check_database_user
}

# create index on tables
create_index () {
 /usr/bin/psql -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB < /schema/MetChemIndex.sql
}

remove_duplicates () {
 # write query
 echo "begin;" >> /tmp/remove_duplicates.query  
 echo "create temp table duplicates as select * from (SELECT inchi_key, ROW_NUMBER() OVER(PARTITION BY inchi_key ORDER BY inchi_key asc) AS Row FROM compound) dups where dups.Row > 1;" >> /tmp/remove_duplicates.query
 echo 'create or replace function check_duplicates() returns void as $$' >> /tmp/remove_duplicates.query
 echo  "DECLARE" >> /tmp/remove_duplicates.query
 echo "  key duplicates.inchi_key%TYPE;" >> /tmp/remove_duplicates.query
 echo "BEGIN" >> /tmp/remove_duplicates.query
 echo " FOR key IN SELECT inchi_key FROM duplicates" >> /tmp/remove_duplicates.query
 echo "  LOOP" >> /tmp/remove_duplicates.query
 echo "   update substance set compound_id=(select compound_id from compound where inchi_key=key limit 1) where compound_id in (select compound_id from compound where inchi_key=key);" >> /tmp/remove_duplicates.query
 echo "   delete from compound where inchi_key=key and compound_id!=(select compound_id from compound where inchi_key=key limit 1);" >> /tmp/remove_duplicates.query
 echo "  END LOOP;" >> /tmp/remove_duplicates.query
 echo " RETURN;" >> /tmp/remove_duplicates.query
 echo "END;" >> /tmp/remove_duplicates.query
 echo '$$ language plpgsql;' >> /tmp/remove_duplicates.query
 echo "select check_duplicates();" >> /tmp/remove_duplicates.query
 echo "commit;" >> /tmp/remove_duplicates.query
 # run query
 /usr/bin/psql -f /tmp/remove_duplicates.query -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null
 rm /tmp/remove_duplicates.query
}

wait_for_database () {
 until /usr/bin/psql -h ${POSTGRES_IP} -U $POSTGRES_USER -d $POSTGRES_DB -c '\l' &> /dev/null; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
 done
 >&2 echo "Postgres is up - executing command"
}
