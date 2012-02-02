#!/bin/sh
DBNAME=north-holland
START=$(python -c'import time; print repr(time.time())')

psql -d $DBNAME -v point="'SRID=4326;POINT(4.8799 52.3931)'" -f sql/test_closestpoint.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v point="'SRID=4326;POINT(4.9465 52.3973)'" -f sql/test_closestpoint.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v point="'SRID=4326;POINT(5.11160 52.77358)'" -f sql/test_closestpoint.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v point="'SRID=4326;POINT(5.10554 52.76486)'" -f sql/test_closestpoint.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)
