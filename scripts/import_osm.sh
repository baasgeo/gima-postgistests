#!/bin/sh
#One-off task to create an empty database
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

echo "Importing osm file with osm2pgsql"
osm2pgsql --slim --database $DBNAME --style /usr/local/share/osm2pgsql/default.style --latlong --multi-geometry --number-processes 2 $IMPORTOSM > /dev/null 2>&1 #--proj EPSG:4326
#psql -d $DBNAME -f sql/create_geography.sql
psql -d $DBNAME -c "VACUUM"