#!/bin/sh
DBNAME=north-holland
START=$(python -c'import time; print repr(time.time())')

psql -d $DBNAME -v bbox="5.09623, 52.77227, 5.10315, 52.76724, 4326" -f sql/test_gml.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v bbox="5.10528, 52.76338, 5.10885, 52.76078, 4326" -f sql/test_gml.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v bbox="4.81342, 52.43037, 4.98180, 52.32305, 4326" -f sql/test_gml.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v bbox="4.73166, 52.68332, 4.98294, 52.37542, 4326" -f sql/test_gml.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)