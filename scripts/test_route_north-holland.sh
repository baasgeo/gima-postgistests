#!/bin/sh
DBNAME=north-holland
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v start="'SRID=4326;POINT(4.8862 52.3677)'" -v end="'SRID=4326;POINT(4.8594 52.3576)'" -f sql/test_route.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v start="'SRID=4326;POINT(4.8620 52.3282)'" -v end="'SRID=4326;POINT(4.8873 52.3257)'" -f sql/test_route.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v start="'SRID=4326;POINT(5.09060 52.76522)'" -v end="'SRID=4326;POINT(4.88557 52.37674)'" -f sql/test_route.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v start="'SRID=4326;POINT(5.09060 52.76522)'" -v end="'SRID=4326;POINT(5.10949 52.76080)'" -f sql/test_route.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)