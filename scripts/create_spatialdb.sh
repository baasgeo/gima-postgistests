#!/bin/sh
DBNAME=spatial
dropdb $DBNAME
createdb $DBNAME
createlang plpgsql $DBNAME
psql -d $DBNAME -f /usr/local/share/postgis/postgis.sql
#psql -d $DBNAME -f /usr/local/share/postgis/postgis_comments.sql
psql -d $DBNAME -f /usr/local/share/postgis/spatial_ref_sys.sql
