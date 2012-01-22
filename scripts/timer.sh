#!/bin/bash
STARTTIME=$(python -c'import time; print repr(time.time())')
# do something
# start your script work here
./$1
# your logic ends here
ENDTIME=$(python -c'import time; print repr(time.time())')
ECHO "Elapsed time: " $(bc -l <<< $ENDTIME-$STARTTIME)
./backtodashboard.sh
