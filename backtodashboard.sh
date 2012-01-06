read -p "Press ENTER for the dashboard or q to exit: " choice

case $choice in
q) quit;;
*) exec ./dashboard.sh;;
esac

