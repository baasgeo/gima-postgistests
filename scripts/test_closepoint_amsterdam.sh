#!/bin/sh
DBNAME=amsterdam
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v point="'SRID=4326;POINT(4.8949 52.3692)'" -f sql/test_closestpoint.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v point="'SRID=4326;POINT(4.8949 52.3692)'" -f sql/test_closestpoint.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v point="'SRID=4326;POINT(4.8949 52.3692)'" -f sql/test_closestpoint.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v point="'SRID=4326;POINT(4.8949 52.3692)'" -f sql/test_closestpoint.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)
