#!/bin/sh
#One-off task to create an empty database
DBNAME=projectdata

# if exists, remove the previous database
dropdb $DBNAME

# create database
createdb $DBNAME
createlang plpgsql $DBNAME

# add PostGIS functions
echo "Adding PostGIS functions..."
psql -d $DBNAME -f /usr/local/share/postgis/postgis.sql 
psql -d $DBNAME -f /usr/local/share/postgis/spatial_ref_sys.sql

echo "Creating boundary boxes"
psql -d $DBNAME -v bbox="3.270, 53.530, 7.300, 50.850, 4326" -v bboxname="'4'" -f ../sql/insert_boundary.sql
psql -d $DBNAME -v bbox="4.445, 52.98, 5.351, 52.216, 4326" -v bboxname="'3'" -f ../sql/insert_boundary.sql
psql -d $DBNAME -v bbox="4.808, 52.4338, 4.993, 52.3137, 4326" -v bboxname="'2'" -f ../sql/insert_boundary.sql
psql -d $DBNAME -v bbox="5.0859, 52.7756, 5.1227, 52.7566, 4326" -v bboxname="'1'" -f ../sql/insert_boundary.sql

