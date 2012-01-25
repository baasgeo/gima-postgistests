#!/bin/sh
#One-off task to delete databases
DBNAME=$1

# if exists, remove the previous database
dropdb $DBNAME