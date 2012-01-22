#!/bin/sh
DBNAME=medemblik

psql -d $DBNAME -f sql/create_topology.sql
