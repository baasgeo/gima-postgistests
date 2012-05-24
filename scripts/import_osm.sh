#!/bin/sh
#One-off task to create an osm database
DBNAME=$1
IMPORTOSM=/Volumes/Data/Users/bartbaas/data/osm/$1.osm

# if exists, remove the previous database
dropdb $DBNAME

# create routing database
createdb $DBNAME
createlang plpgsql $DBNAME

# add PostGIS functions
echo "Adding PostGIS functions..."
psql -d $DBNAME -f /usr/local/share/postgis/postgis.sql > /dev/null 2>&1 
psql -d $DBNAME -f /usr/local/share/postgis/spatial_ref_sys.sql > /dev/null 2>&1 

# add pgRouting core functions
echo "Adding pgRouting functions..."
psql -d $DBNAME -f /usr/local/share/postlbs/routing_core.sql > /dev/null 2>&1 
psql -d $DBNAME -f /usr/local/share/postlbs/routing_core_wrappers.sql > /dev/null 2>&1 
psql -d $DBNAME -f /usr/local/share/postlbs/routing_topology.sql > /dev/null 2>&1 

echo "Importing $1 osm file with osm2pgsql"
osm2pgsql --slim --database $DBNAME --keep-coastlines --style /usr/local/share/osm2pgsql/default.style --latlong --host localhost --port 5432 --number-processes 2 $IMPORTOSM #--number-processes 2 > /dev/null 2>&1 #--proj EPSG:4326
#psql -d $DBNAME -f sql/primary_key.sql
psql -d $DBNAME -c "VACUUM"