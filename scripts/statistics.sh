#!/bin/sh
DBNAME=$1
START=$(python -c'import time; print repr(time.time())')

psql -d $DBNAME -v database="'$1'" -f sql/statistics.sql
