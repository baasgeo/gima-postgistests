#!/bin/sh
DBNAME=$1

psql -d $DBNAME -f sql/create_topology.sql
psql -d $DBNAME -c "VACUUM"
