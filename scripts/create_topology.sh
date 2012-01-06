#!/bin/sh
DBNAME=amsterdam

psql -d $DBNAME -f sql/create_topology.sql
