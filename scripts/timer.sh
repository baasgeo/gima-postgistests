#!/bin/bash
#START=$(date +%s%N)
# do something
# start your script work here
time ./$1
# your logic ends here
#END=$(date +%s%N)
#DIFF=$(( $END - $START ))
#echo "It took $DIFF seconds"
./backtodashboard.sh
