#!/bin/sh
#One-off task to delete a database
DBNAME=$1

# if exists, remove the previous database
dropdb $DBNAME
#vacuumdb --all 
#reindexdb --all