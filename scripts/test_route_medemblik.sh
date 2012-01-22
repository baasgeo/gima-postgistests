#!/bin/sh
DBNAME=medemblik
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v start="'SRID=4326;POINT(5.09060 52.76522)'" -v end="'SRID=4326;POINT(5.10949 52.76080)'" -f sql/test_route.sql
END=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END-$START)
