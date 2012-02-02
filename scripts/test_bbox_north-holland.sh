#!/bin/sh
DBNAME=north-holland
START=$(python -c'import time; print repr(time.time())')

#psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v bbox="5.09623, 52.77227, 5.10315, 52.76724, 4326" -f sql/test_bbox.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v bbox="5.10528, 52.76338, 5.10885, 52.76078, 4326" -f sql/test_bbox.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v bbox="4.88557, 52.37674, 4.91214, 52.36694, 4326" -f sql/test_bbox.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v bbox="4.84779, 52.37478, 4.86592, 52.36498, 4326" -f sql/test_bbox.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)

psql -d $DBNAME -v bbox="4.94322, 52.34834, 4.96767, 52.33037, 4326" -f sql/test_bbox.sql
END5=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END5-$END4)