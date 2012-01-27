#!/bin/sh
DBNAME=medemblik
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v bbox="5.09623, 52.77227, 5.10315, 52.76724, 4326" -f sql/test_bbox.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v bbox="5.10528, 52.76338, 5.10885, 52.76078, 4326" -f sql/test_bbox.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)
