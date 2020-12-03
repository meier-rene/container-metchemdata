#!/bin/bash

################
# includes
################

source /scripts/functions.sh
source /scripts/pubchem.sh
source /scripts/kegg.sh
source /scripts/kegg_derivatised.sh
source /scripts/chebi.sh
source /scripts/lipidmaps.sh
source /scripts/swisslipids.sh
source /scripts/coconut.sh
source /scripts/hmdb.sh

wait_for_database

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
  init_database >> $LOG_FOLDER/init/output.log 2>> $LOG_FOLDER/init/output.err
 else
  init_database
 fi
 echo "database initialised"
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
  insert_pubchem >> $LOG_FOLDER/pubchem/output.log 2>> $LOG_FOLDER/pubchem/output.err
 else
  insert_pubchem
 fi
 echo "pubchem inserted"
fi

################
# fill data hmdb
################

# check whether $EXEC contains HMDB and update/create entries
TO_FIND="HMDB"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder hmdb
 if [ -e $LOG_FOLDER/hmdb/ ]
 then
  insert_hmdb >> $LOG_FOLDER/hmdb/output.log 2>> $LOG_FOLDER/hmdb/output.err
 else
  insert_hmdb
 fi
 echo "hmdb inserted"
fi

################
# fill data kegg_derivatised
################

# check whether $EXEC contains KEGG_DERIVATISED and update/create entries
TO_FIND="KEGG_DERIVATISED"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder kegg_derivatised
 if [ -e $LOG_FOLDER/kegg_derivatised/ ]
 then
  insert_kegg_derivatised >> $LOG_FOLDER/kegg_derivatised/output.log 2>> $LOG_FOLDER/kegg_derivatised/output.err
 else
  insert_kegg_derivatised
 fi
 echo "kegg_derivatised inserted"
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
  insert_kegg >> $LOG_FOLDER/kegg/output.log 2>> $LOG_FOLDER/kegg/output.err
 else
  insert_kegg
 fi
 echo "kegg inserted"
fi

################
# fill data lipidmaps
################

# check whether $EXEC contains LIPIDMAPS and update/create entries
TO_FIND="LIPIDMAPS"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder lipidmaps
 if [ -e $LOG_FOLDER/lipidmaps/ ]
 then
  insert_lipidmaps >> $LOG_FOLDER/lipidmaps/output.log 2>> $LOG_FOLDER/lipidmaps/output.err
 else
  insert_lipidmaps
 fi
 echo "lipidmaps inserted"
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
  insert_chebi >> $LOG_FOLDER/chebi/output.log 2>> $LOG_FOLDER/chebi/output.err
 else
  insert_chebi
 fi
 echo "chebi inserted"
fi

################
# fill data swisslipids
################

# check whether $EXEC contains SWISSLIPIDS and update/create entries
TO_FIND="SWISSLIPIDS"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder swisslipids
 if [ -e $LOG_FOLDER/swisslipids/ ]
 then
  insert_swisslipids >> $LOG_FOLDER/swisslipids/output.log 2>> $LOG_FOLDER/swisslipids/output.err
 else
  insert_swisslipids
 fi
 echo "swisslipids inserted"
fi

################
# fill data COCONUT
################

# check whether $EXEC contains COCONUT and update/create entries
TO_FIND="COCONUT"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder coconut
 if [ -e $LOG_FOLDER/coconut/ ]
 then
  insert_coconut >> $LOG_FOLDER/coconut/output.log 2>> $LOG_FOLDER/coconut/output.err
 else
  insert_coconut
 fi
 echo "COCONUT inserted"
fi


################
# create index on database tables
################

# check whether $EXEC contains INDEX and create index
TO_FIND="INDEX"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder create_index
 if [ -e $LOG_FOLDER/create_index/ ]
 then
  create_index >> $LOG_FOLDER/create_index/output.log 2>> $LOG_FOLDER/create_index/output.err
 else
  create_index
 fi
 echo "index created"
fi
         
################
# remove duplicates
################

# check whether $EXEC contains DUPLICATES and update/create entries
TO_FIND="DUPLICATES"
if echo $EXEC | grep -q -e "^$TO_FIND,\|,$TO_FIND$\|,$TO_FIND,\|^$TO_FIND$"
then
 check_log_folder duplicates
 if [ -e $LOG_FOLDER/duplicates/ ]
 then
  remove_duplicates >> $LOG_FOLDER/duplicates/output.log 2>> $LOG_FOLDER/duplicates/output.err
 else
  remove_duplicates
 fi
 echo "duplicates removed"
fi
