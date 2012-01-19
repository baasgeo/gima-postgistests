#!/bin/sh
DBNAME=amsterdam

psql -d $DBNAME -f sql/test_route2.sql
psql -d $DBNAME -v start="'SRID=4326;POINT(4.8949258 52.3692863)'" -v end="'SRID=4326;POINT(4.8594936 52.3576170)'" -f sql/test_route.sql
