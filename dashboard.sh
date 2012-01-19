#!/bin/bash

# clear the screen
tput clear

# Move cursor to screen location X,Y (top left is 0,0)
tput cup 3 5

# Set a foreground colour using ANSI escape
tput setaf 3
echo "PostGIS DashBoard"
tput sgr0

# Set reverse video mode
tput rev
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
echo "8.  Test1"

tput cup 8 45
echo "9.  Test2 - route"

tput cup 9 45
echo "10. Test3"

tput cup 10 45
echo "11. Test4"

tput cup 11 45
echo "12. Test5"

# Set bold mode
tput bold
tput cup 16 5
read -p "Enter your choice [1-12] or q to exit: " choice
tput sgr0

#call the required shell or set QUIT and continue the loop, or continue the loop on any other input
case $choice in
1) exec scripts/timer.sh scripts/postgis_start.sh;;
2) echo "not implemented yet"; ./backtodashboard.sh;;
3) time scripts/postgis_stop.sh; ./backtodashboard.sh;;
4) time scripts/postgis_clean.sh; ./backtodashboard.sh;;
5) time scripts/import_osm2pgsql.sh; ./backtodashboard.sh;;
6) time scripts/create_topology.sh; ./backtodashboard.sh;;
7) echo "not implemented yet"; ./backtodashboard.sh;;
8) time scripts/stop_postgis.sh; ./backtodashboard.sh;;
9) exec scripts/timer.sh scripts/test_route.sh;;
10) echo "not implemented yet"; ./backtodashboard.sh;;
11) echo "not implemented yet"; ./backtodashboard.sh;;
12) echo "not implemented yet"; ./backtodashboard.sh;;
esac
