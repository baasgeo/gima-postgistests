#!/bin/sh
DBNAME=medemblik
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v start="'SRID=4326;POINT(5.09060 52.76522)'" -v end="'SRID=4326;POINT(5.10949 52.76080)'" -f sql/test_route.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v start="'SRID=4326;POINT(5.11160 52.77358)'" -v end="'SRID=4326;POINT(5.10554 52.76486)'" -f sql/test_route.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v start="'SRID=4326;POINT(5.09623 52.77227)'" -v end="'SRID=4326;POINT(5.10315 52.76724)'" -f sql/test_route.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v start="'SRID=4326;POINT(5.10528 52.76338)'" -v end="'SRID=4326;POINT(5.10885 52.76078)'" -f sql/test_route.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)