
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
  /usr/bin/psql -c "CREATE USER metchemro with UNENCRYPTED password '$password';" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
  /usr/bin/psql -c "GRANT CONNECT ON DATABASE $POSTGRES_DB to metchemro;" -h $POSTGRES_IP -U $POSTGRES_USER -qtA -d $POSTGRES_DB
 fi
}


# init database and create tables
# initial run needed to do once
# !!! deletes all tables in the database first !!!
init_database_from_github () {
 /usr/bin/psql -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB < /schema/MetChemSchema.sql
 /usr/bin/psql -h $POSTGRES_IP -U $POSTGRES_USER -d $POSTGRES_DB < /schema/MetChemIndex.sql
 check_database_user
}
