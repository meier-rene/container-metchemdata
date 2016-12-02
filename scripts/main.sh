#!/bin/bash

################
# includes
################

source /scripts/functions.sh
source /scripts/pubchem.sh
source /scripts/kegg.sh
source /scripts/chebi.sh

if [ "$(check_database_exists)" -eq "0" ]
then
 echo "database $POSTGRES_DB not found"
 exit 1
fi

##
# create table functions
##

################
################
#
# DO THE WORK!!!
#
################
################

################
# init database tables
################

# check whether $EXEC contains INIT and initialise database by creating the schema
TO_FIND="INIT"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder init
 if [ -e $LOG_FOLDER/init/ ]
 then
  init_database_from_github >> $LOG_FOLDER/init/output.log 2>> $LOG_FOLDER/init/output.err
 else
  init_database_from_github
 fi
fi

################
# fill data pubchem
################

# check whether $EXEC contains PUBCHEM and update/create entries
TO_FIND="PUBCHEM"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder pubchem
 if [ -e $LOG_FOLDER/pubchem/ ]
 then
  update_pubchem >> $LOG_FOLDER/pubchem/output.log 2>> $LOG_FOLDER/pubchem/output.err
 else
  update_pubchem
 fi
fi

################
# fill data kegg
################

# check whether $EXEC contains KEGG and update/create entries
TO_FIND="KEGG"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder kegg
 if [ -e $LOG_FOLDER/kegg/ ]
 then
  update_kegg >> $LOG_FOLDER/kegg/output.log 2>> $LOG_FOLDER/kegg/output.err
 else
  update_kegg
 fi
fi

################
# fill data chebi
################

# check whether $EXEC contains CHEBI and update/create entries
TO_FIND="CHEBI"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder chebi
 if [ -e $LOG_FOLDER/chebi/ ]
 then
  update_chebi >> $LOG_FOLDER/chebi/output.log 2>> $LOG_FOLDER/chebi/output.err
 else
  update_chebi
 fi
fi

