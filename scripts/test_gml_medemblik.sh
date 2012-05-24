#!/bin/sh
DBNAME=medemblik
START=$(python -c'import time; print repr(time.time())')

psql -d $DBNAME -v bbox="5.09623, 52.77227, 5.10315, 52.76724, 4326" -f sql/test_gml.sql
END1=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END1-$START)

psql -d $DBNAME -v bbox="5.10528, 52.76338, 5.10885, 52.76078, 4326" -f sql/test_gml.sql
END2=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END2-$END1)

psql -d $DBNAME -v bbox="5.09492, 52.77134, 5.11173, 52.76151, 4326" -f sql/test_gml.sql
END3=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END3-$END2)

psql -d $DBNAME -v bbox="5.10725, 52.77271, 5.11791, 52.76455, 4326" -f sql/test_gml.sql
END4=$(python -c'import time; print repr(time.time())')
ECHO "Took: " $(bc -l <<< $END4-$END3)
