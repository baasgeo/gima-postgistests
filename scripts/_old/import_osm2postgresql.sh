#!/bin/sh
#One-off task to import osm data
DBNAME=amsterdam
IMPORTOSM=/Volumes/Data/Users/bartbaas/data/osm/amsterdam.osm
dropdb $DBNAME
#createdb $DBNAME
#createlang plpgsql $DBNAME
#psql -d $DBNAME -f /usr/local/share/postgresql/contrib/hstore.sql
#psql -d $DBNAME -f /usr/local/share/postgis/postgis.sql
#psql -d $DBNAME -f /usr/local/share/postgis/spatial_ref_sys.sql
./osm2postgresql_04.sh --createdb --dbname $DBNAME --postgis /usr/local/share/postgis/ --hstore /usr/share/postgresql/contrib/ --osm $IMPORTOSM
rm osmosis-0.*.tgz* 
rm -r /Volumes/Data/Users/bartbaas/Dropbox/GIMA/modules/module8/source/pgscripts/tempamsterdam 
rm -r osmosis-*/ 