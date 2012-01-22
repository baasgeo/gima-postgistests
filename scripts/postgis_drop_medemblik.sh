#!/bin/sh
#One-off task to delete databases
DBNAME=medemblik

# if exists, remove the previous database
dropdb $DBNAME