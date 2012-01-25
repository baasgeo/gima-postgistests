#!/bin/sh
DBNAME=$1
START=$(python -c'import time; print repr(time.time())')

psql -d $DBNAME -f sql/test_empty.sql
