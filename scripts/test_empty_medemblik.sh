#!/bin/sh
DBNAME=medemblik
START=$(python -c'import time; print repr(time.time())')

psql -d $DBNAME -f sql/test_empty.sql
