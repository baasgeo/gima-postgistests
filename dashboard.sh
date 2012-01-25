#!/bin/bash
python -c'import time; print repr(time.time())'

DATASET=$1

if [ -z "$DATASET" ]; then 	# -n tests to see if the argument is non empty
	DATASET="medemblik"
fi

function reload {
	exec ./dashboard.sh $1
}

function backtodashboard {
	read -p "Press ENTER for the dashboard or q to exit: " choice
	
	case $choice in
	q) echo "quit";;
	*) exec ./dashboard.sh $DATASET;;
	esac
}

function timer {
	STARTTIME=$(python -c'import time; print repr(time.time())')
	# do something
	# start your script work here
	echo "Executing:" $1 "for dataset" $DATASET
	./$1 $DATASET
	# your logic ends here
	ENDTIME=$(python -c'import time; print repr(time.time())')
	ECHO "Elapsed time: " $(bc -l <<< $ENDTIME-$STARTTIME)
	backtodashboard
}

# clear the screen
tput clear

# Move cursor to screen location X,Y (top left is 0,0)
tput cup 1 5

# Set a foreground colour using ANSI escape
tput setaf 3
echo "PostGIS DashBoard -" $DATASET | tr a-z A-Z
tput sgr0

# Set reverse video mode
tput rev
tput cup 3 5
echo "A) Medemblik"
tput cup 3 25
echo "B) Amsterdam"
tput cup 3 45
echo "C) Netherlands"
tput sgr0

# Set reverse video mode
tput setaf 1
tput cup 5 5
echo "Instance"
tput cup 11 5
echo "Data"
tput cup 5 45
echo "Tests"
tput sgr0

tput cup 6 5
echo "1. Start database"

tput cup 7 5
echo "2. Statistics"

tput cup 8 5
echo "3. Stop database"

tput cup 9 5
echo "4. Delete databases"

tput cup 12 5
echo "5. Import osm data"

tput cup 13 5
echo "6. Create route topology"

tput cup 6 45
echo "7.  Empty SQL call"

tput cup 7 45
echo "8.  Test1 - bounding box"

tput cup 8 45
echo "9.  Test2"

tput cup 9 45
echo "10. Test3 - route"

tput cup 10 45
echo "11. Test4"

tput cup 11 45
echo "12. Test5"

# Set bold mode
tput bold
tput cup 16 5
read -p "Enter your choice [A-C] or [1-12] or q to exit: " choice
tput sgr0

#call the required shell or set QUIT and continue the loop, or continue the loop on any other input
case $choice in
A) reload "medemblik";;
B) reload "amsterdam";;
C) reload "netherlands";;
1) timer scripts/postgis_start.sh;;
2) echo "not implemented yet";;
3) timer scripts/postgis_stop.sh;;
4) timer scripts/postgis_drop.sh $DATASET;;
5) timer scripts/import_osm.sh $DATASET;;
6) timer scripts/create_topology.sh $DATASET;;
7) timer scripts/test_empty.sh $DATASET;;
8) timer scripts/test_bbox_$DATASET.sh;;
9) echo "not implemented yet";;
10) timer scripts/test_route_$DATASET.sh;;
11) echo "not implemented yet";;
12) echo "not implemented yet";;
esac
