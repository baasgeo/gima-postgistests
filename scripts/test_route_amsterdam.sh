#!/bin/sh
DBNAME=amsterdam
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v start="'SRID=4326;POINT(4.8949 52.3692)'" -v end="'SRID=4326;POINT(4.8594 52.3576)'" -f sql/test_route.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v start="'SRID=4326;POINT(4.9217 52.3602)'" -v end="'SRID=4326;POINT(4.9412 52.3302)'" -f sql/test_route.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)
