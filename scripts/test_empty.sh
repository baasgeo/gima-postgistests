#!/bin/sh
DBNAME=$1
START=$(python -c'import time; print repr(time.time())')

END1=$(python -c'import time; print repr(time.time())')
PTIME=$(bc -l <<< $END1-$START)
ECHO "Python: " $(bc -l <<< $PTIME)

psql -d $DBNAME -f sql/test_empty.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "PSQL: " $(bc -l <<< $END2-$END1-$PTIME)
