#!/bin/sh
DBNAME=north-holland
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v start="'SRID=4326;POINT(4.8949 52.3692)'" -v end="'SRID=4326;POINT(4.8594 52.3576)'" -f sql/test_route.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v start="'SRID=4326;POINT(4.9217 52.3602)'" -v end="'SRID=4326;POINT(4.9412 52.3302)'" -f sql/test_route.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v start="'SRID=4326;POINT(4.88557 52.37674)'" -v end="'SRID=4326;POINT(4.91214 52.36694)'" -f sql/test_route.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v start="'SRID=4326;POINT(5.09060 52.76522)'" -v end="'SRID=4326;POINT(4.88557 52.37674)'" -f sql/test_route.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)

psql -d $DBNAME -v start="'SRID=4326;POINT(4.84779 52.37478)'" -v end="'SRID=4326;POINT(4.86592 52.36498)'" -f sql/test_route.sql
END5=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END5-$END4)