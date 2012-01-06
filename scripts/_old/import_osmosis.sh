#!/bin/sh
#One-off task to create an empty database
DBNAME=medemblik
IMPORTOSM=/Volumes/Data/Users/bartbaas/data/osm/medemblik.osm
dropdb $DBNAME
createdb $DBNAME
createlang plpgsql $DBNAME
#psql -d $DBNAME -f /usr/local/share/postgresql/contrib/hstore.sql
psql -d $DBNAME -f /usr/local/share/postgis/postgis.sql
psql -d $DBNAME -f /usr/local/share/postgis/spatial_ref_sys.sql
psql -d $DBNAME -f osmosis/script/pgsimple_schema_0.6.sql
#psql -d $DBNAME -f osmosis/script/pgsimple_schema_0.6_action.sql
#psql -d $DBNAME -f osmosis/script/pgsimple_schema_0.6_bbox.sql
psql -d $DBNAME -f osmosis/script/pgsimple_schema_0.6_linestring.sql
osmosis/bin/osmosis --read-xml file=$IMPORTOSM --write-pgsimp database=$DBNAME user=bartbaas password=bartje
#osmosis/bin/osmosis --read-xml file=$IMPORTOSM --write-pgsql database=$DBNAME user=bartbaas password=bartje
