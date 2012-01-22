#!/bin/sh
DBNAME=amsterdam
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v bbox="4.88557, 52.37674, 4.91214, 52.36694, 4326" -f sql/test_bbox.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v bbox="4.84779, 52.37478, 4.86592, 52.36498, 4326" -f sql/test_bbox.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v bbox="4.94322, 52.34834, 4.96767, 52.33037, 4326" -f sql/test_bbox.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)
