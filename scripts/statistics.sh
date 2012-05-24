#!/bin/sh
DBNAME=$1
START=$(python -c'import time; print repr(time.time())')

ECHO "Warming up..."
psql -d $DBNAME -f sql/warm-up.sql

ECHO "Gettings statistics..."
psql -c -d $DBNAME -v database="'$1'" -f sql/statistics.sql
