#!/bin/bash
python -c'import time; print repr(time.time())'
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
read -p "Enter your choice [1-12] or q to exit: " choice
tput sgr0

#call the required shell or set QUIT and continue the loop, or continue the loop on any other input
case $choice in
1) exec scripts/timer.sh scripts/postgis_start.sh;;
2) echo "not implemented yet"; ./backtodashboard.sh;;
3) exec scripts/timer.sh scripts/postgis_stop.sh;;
4) exec scripts/timer.sh scripts/postgis_drop_amsterdam.sh;;
5) exec scripts/timer.sh scripts/import_osmamsterdam.sh;;
6) exec scripts/timer.sh scripts/create_topology.sh;;
7) exec scripts/timer.sh scripts/test_empty_amsterdam.sh;;
8) exec scripts/timer.sh scripts/test_bbox_amsterdam.sh;;
9) echo "not implemented yet"; ./backtodashboard.sh;;
10) exec scripts/timer.sh scripts/test_route_amsterdam.sh;;
11) echo "not implemented yet"; ./backtodashboard.sh;;
12) echo "not implemented yet"; ./backtodashboard.sh;;
esac
