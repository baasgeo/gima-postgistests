#!/bin/sh
#One-off task to create an empty database
DBNAME=amsterdam
IMPORTOSM=/Volumes/Data/Users/bartbaas/data/osm/amsterdam.osm

# if exists, remove the previous database
dropdb $DBNAME

# create routing database
createdb $DBNAME
createlang plpgsql $DBNAME

# add PostGIS functions
psql -d $DBNAME -f /usr/local/share/postgis/postgis.sql
psql -d $DBNAME -f /usr/local/share/postgis/spatial_ref_sys.sql

# add pgRouting core functions
psql -d $DBNAME -f /usr/local/share/postlbs/routing_core.sql
psql -d $DBNAME -f /usr/local/share/postlbs/routing_core_wrappers.sql
psql -d $DBNAME -f /usr/local/share/postlbs/routing_topology.sql

osm2pgsql --slim --database $DBNAME --style /usr/local/share/osm2pgsql/default.style --latlong --multi-geometry --number-processes 2 $IMPORTOSM #--proj EPSG:4326
psql -d $DBNAME -f sql/create_geography.sql
psql -d $DBNAME -c "VACUUM FREEZE"