#!/bin/sh
DBNAME=amsterdam

psql -d $DBNAME -f sql/test_route.sql
