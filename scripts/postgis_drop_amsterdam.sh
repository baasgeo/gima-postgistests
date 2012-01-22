#!/bin/sh
#One-off task to delete databases
DBNAME=amsterdam

# if exists, remove the previous database
dropdb $DBNAME