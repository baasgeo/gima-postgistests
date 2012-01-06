#!/bin/bash
# This is the osm2postgresql script, a GNU/Linux bash
# script to load openstreetmap data into a postgresql
# database (creating if necessary the database with
# postgis and hstore extensions)
# This program is distributed under the terms of the GNU/General Public License
# version 2 or later (at your choice)
# Copyright 2011 Mayeul KAUFFMANN
# There is no warranty for this free software. Use at your own risk!

version="osm2postgresql version 0.4 (4 July 2011)"
scriptfile="./osm2postgresql_04.sh"

### Example usages:
# ./osm2postgresql_04.sh --help
### Other examples:

### The following will download the Postgres installer, install it, create a
### database, configure it, download osmosis, run it, create the geometries from
### the raw OSM data, and a bit more:
# ./osm2postgresql_04.sh -p 5433 -i -I /hometb/mk/sig/software/Postgres841 -a x64

# ./osm2postgresql_04.sh -p 5432 -P /usr/share/postgresql/8.4/contrib/postgis-1.5 -H /usr/share/postgresql/8.4/contrib --osm /home/mk/disque-80Go/geoportail/italie/maps/mottarone_San-Giulio.osm

# ./osm2postgresql_04.sh -p 5432 -P /usr/share/postgresql/8.4/contrib/postgis-1.5 -H /usr/share/postgresql/8.4/contrib --dbname osmtest --EPSG 900913 --osm /hometb/mk/sig/OSM/raw_osm/monaco.osm

# ./osm2postgresql_04.sh -p 5432 -P /usr/share/postgresql/8.4/contrib/postgis-1.5 -H /usr/share/postgresql/8.4/contrib --dbname monaco --EPSG 900913 --tablespace monaco --datadir /hometb/mk/sig/OSM/tablespacesmk/monaco --temporarydir /hometb/mk/sig/OSM/tempmonaco --osm /hometb/mk/sig/OSM/raw_osm/monaco.osm &> log_import_osm_monaco.txt

# ./osm2postgresql_04.sh -p 5432 -P /usr/share/postgresql/8.4/contrib/postgis-1.5 -H /usr/share/postgresql/8.4/contrib --dbname osm_north_italy --EPSG 900913 --tablespace osm_north_italy --datadir /hometb/mk/sig/OSM/tablespacesmk/osm_north_italy --temporarydir /hometb/mk/sig/OSM/temposm_north_italy --osm /hometb/mk/sig/OSM/raw_osm/italy_north.osm


# cd /home/mk/disque-80Go/geoportail/italie/maps/dev_symbol_levels/
# ./osm2postgresql_04.sh -p 5432 -P /usr/share/postgresql/8.4/contrib/postgis-1.5 -H /usr/share/postgresql/8.4/contrib --dbname osm_rhone_alpes_32631 --EPSG 32631 --tablespace osm_rhone_alpes_32631 --datadir /hometb/mk/sig/OSM/tablespacesmk/osm_rhone_alpes_32631 --temporarydir /hometb/mk/sig/OSM/temposm_osm_rhone_alpes_32631 --osm /hometb/mk/sig/OSM/raw_osm/rhone_alpes.osm &> log_import_osm_osm_rhone_alpes_32631_bis.txt


## Release notes:
# Known bugs
# spaces and dashes in options not handled correctly, use underscores in options instead
# 
# Please note: The install="yes" option is ALPHA quality and tested on Kubuntu
#  10.10 64 bits only. It may prevent the Novell evolution email client to run
# on some platform; see:
# http://forums.enterprisedb.com/posts/list/2616.page
# Most of the remaining code is beta quality. The SQL part is currently
# the most reliable (tested on full italy.osm & switzerland.osm and on a few
# other sets) and used in production.

# The management of rights with postgresql is tricky. The easiest is to use the --install option.
# The best is to let the current user connect to a local database (with same name
# as the user name) through a socket (you may need to configure postgresql to trust this).
# Figuring out what is the best universal solution for this script is still a work in progress...
#  You might also want to allow your user to do
#  (without password): sudo /usr/bin/psql
## To do it, you should know how to use 'visudo'
# The following assumes your default editor is vi. If this is not the case,
##  you may want to change it typing:
# sudo select-editor
## You will be proposed a list of editors
## Then type the following command on the shell (without the sharp '#'):
# sudo visudo
## Go to the end of the last line of the file with the keyboard then press
# the 'i' key to be in insertion mode
## Add the following line on a new line at the end of the file:
# yourusername  ALL=(postgres) /usr/bin/psql *
## To exit without saving, type the ESCAPE key, then type (without the sharp):
# :q!
# To exit after saving (w=write, q=quit), type the ESCAPE key, then type
# (without the sharp):
# :wq


#####################
# Code starts here


f () {
    errcode=$? # save the exit code
    echo "Error $errcode. The command which triggered the error was:"
    echo "$BASH_COMMAND"
    echo "on line ${BASH_LINENO[0]} of the osm2postgresql script."
    echo -e $how_to_remove 
    exit $errcode
}
trap f ERR


NOW=$(date +"%Y-%m-%d_%H:%M:%S")
echo "Time: Started $NOW"
installdir=~/Postgres841
install="no" # by default, assume the server is installed and running
createdb="no" # by default, assume the database is created (with postgis
# and hstore support) and empty and owned by current user (trusted local
# connection with socket without password when logged with a specific linux
# user)

dbname="OSM$NOW"
port=5432
arch="32"
username=`whoami`
EPSG="do_not_reproject"
rivers="cut" # where appropriate, cut rivers, streams... ovelaping riverbanks (nicer rendering)

# http://get.enterprisedb.com/ga/postgresplus-8.4.1-2-linux.bin

usage ()
{
echo "Usage: $scriptfile [OPTION]...  --osm filename.osm  [OPTION]...

EXAMPLE USAGE (download and uncompress, then import into database):
wget -O - http://download.geofabrik.de/osm/europe/monaco.osm.bz2 | bzcat > monaco.osm
$scriptfile --osm monaco.osm
More examples are shown at the end.

MANDATORY PARAMETER:
-f, --file, --osm       name of .osm file to import

OPTIONAL PARAMETERS (NOT FOLLOWED BY A VARIABLE):
--help                  display this help
--version               display the version and date of this script
-i, --install           install a postgres server (using EntrepriseDB installer)
-c, --createdb          create a database
-r, --rivers            keep rivers, streams... untouched (default is to modify them to
                          improve rendering)

OPTIONAL PARAMETERS WHICH MUST BE FOLLOWED BY A VARIABLE:
-d, --dbname            database name to create and/or connect to;
                          with --install or --createdb, default is OSM$NOW
                          otherwise default is `whoami`
-U, --username          username (default: `whoami`)
-h, --host              server host (default is to use a socket with user `whoami`
                          except with --install option: default is 127.0.0.1
-p, --port              server port (default when not using a socket is: 5432)
-O, --options_postgres  any additional psql options to connect to postgres as postgres user
-u, --options_user      any additional psql options to connect to postgres as current user
-t, --tablespace        name of the tablespace to create (only if createdb="yes" and
                          not install="yes" ; will be created in folder 'datadir')
-D, --datadir           where to save the database (with option --install or --tablespace)
-m, --temporarydir      where to save the files created by osmosis
-P, --postgis           folder where to find the sql commands to install postgis in database
-H, --hstore            folder where to find the sql commands to install hstore in database
-E, --EPSG              new SRID (EPSG) code (if you want to reproject the geometries)
                          do not use to keep data in lat/long.
-I, --installdir        where to install the postgres server (with --install option);
                          default is: ~/Postgres841
-x, --psql_folder       folder where psql executable is installed (e.g. /usr/lib/postgresql/9.0/bin/)
                          By default, the script will search in the path.
-a, --arch              architecture when installing the postgres server
                          use "-a x64" for 64 bits; do not use that option for 32 bits
-b, --bash_init_script  the name of the file (e.g. your bash init script) where to add
                         a command that will add the path to 'psql' if using the 
                         --installdir option. Default is ~/.bashrc


The last two parameters are only relevant with the --install option.

EXAMPLES:
$scriptfile --osm monaco.osm
The above command assumes the database is already created (with postgis
and hstore support), is empty and owned by current user (trusted local
connection with socket without password when logged with a specific linux
user, which means running psql from the command line is enough to connect
to the `whoami` database).

If you want a database to be created, you need to provide the paths to postgis.sql
and hstore.sql, for instance with:

$scriptfile --postgis /usr/share/postgresql/8.4/contrib/postgis-1.5 \
  --hstore /usr/share/postgresql/8.4/contrib \
  --createdb   --osm monaco.osm

You can install a server and populate a new database using the EntrebriseDB installer:
$scriptfile --install --osm monaco.osm
In this case, you will be asked your root or sudo password each time it is required.
"
}


## Read parameters from command line
while [ "$1" != "" ]; do
  case $1 in
    --help )            usage
                        exit ;;
    -d | --dbname )     shift # database name to create and/or connect to?
                        dbname=$1 ;;
    -U | --username )   shift
                        username=$1 ;;
    -h | --host )       shift
                        host=$1 ;;
    -p | --port )       shift
                        port=$1 ;;
#     -w | --password )  shift
#                         password=$1 ;; # Unsure because any connected user can see command line
#  parameters thanks to 'ps'. So not implemented yet (Don't use this unless on a single-user machine)
    -O | --options_postgres )  shift # set of other options to connect to postgres as postgres user
                        pgoptions_postgres=$1 ;;
    -u | --options_user )  shift # set of other options to connect to postgres as current user
                        pgoptions_user=$1 ;;
    -i | --install )    install="yes" ;; # install a postgres server?
    -I | --installdir )  shift # where to install it
                        installdir=$1 ;;
    -a | --arch )  shift # use "-a x64" for 64 bits; do not use that option for 32 bits
                        arch=$1 ;;
    -c | --createdb )   createdb="yes" ;; # create a database?
    -D | --datadir )    shift
                        datadir=$1 ;; # where to save the db if you use the --install option
    -m | --temporarydir )    shift
                        temporarydir=$1 ;; # where to save the files created by osmosis
    -t | --tablespace ) shift
                        tablespace=$1 ;; # name of the tablespace to create (only if createdb="yes" and not install="yes" ; will be created in folder 'datadir')
# If you have several hard disks, you can choose which one you want to use (the disk space you use is called a 'TABLESPACE' in postgresql).
    -P | --postgis )     shift  # folder where to find the sql commands to install postgis
                        postgisfolder=$1 ;;
    -H | --hstore )     shift # folder where to find the sql commands to install hstore
                        hstorefolder=$1 ;;
    -E | --EPSG )     shift # new SRID (EPSG code) if you want to reproject the geometries
                        EPSG=$1 ;;
    -r | --rivers )    rivers="keep" ;; # keep rivers, streams... untouched
    -f | --file | --osm ) shift  # osm file to import
                        osmfile=$1 ;;
    -b | --bash_init_script ) shift
                        bash_init_script=$1 ;;
    -x | --psql_folder )       shift
                        psql_folder=$1 ;;


    --version  )        echo $version
                        exit ;;
      * )
  esac
  shift
done

if [ -z "$osmfile" ] ; then
  usage
  exit
fi

if [ -z "$datadir" ] ; then
  datadir="$installdir/data"
fi

if [ -z "$temporarydir" ] ; then
  temporarydir="`pwd`/temp$dbname"
fi

if  [ ! -z "$host" ] ; then
  pgconnect_postgres=" -h $host "
else
  if [ "$install" = "yes" ]; then
  # the installer does not use a socket but a tcp connection...
  host="127.0.0.1"
  pgconnect_postgres=" -h 127.0.0.1 "
  fi
fi

if  [ ! -z "$port" ] ; then
  pgconnect_postgres=" $pgconnect_postgres -p $port "
fi

pgconnect_user=$pgconnect_postgres

if  [ ! -z "$pgoptions_postgres" ] ; then
  pgconnect_postgres=" $pgconnect_postgres $pgoptions_postgres "
fi

if  [ ! -z "$pgoptions_user" ] ; then
  pgconnect_postgres=" $pgconnect_postgres $pgoptions_user "
fi

pgconnect_user=" -d $dbname -U $username $pgconnect_user "


# TODO: defines this HowTo before in case there is an error above
how_to_remove=" ## To delete the imported or temporary data, you might need to \n
## run something similar to this (use with care the lines with the '*'): \n
# To remove osmosis temporary data: \n
rm osmosis-0.*.tgz* \n
rm -r $temporarydir \n
rm -r osmosis-*/ \n
# To delete the imported data, you may need to run: \n
dropdb $pgconnect_postgres $pgoptions_user $dbname \n
# If you created a tablespace: \n
echo \"DROP TABLESPACE $tablespace;\" | psql $pgconnect_postgres $pgoptions_user  \n
# If you created a tablespace or used the --install option: \n
sudo rm -r $datadir \n
"



if [ "$install" = "yes" ]; then
  mkdir -p $installdir
  if [ "$arch" = "x64" ]; then
    archfilestring="-x64"
  else
    archfilestring=""
  fi
  cd $installdir
  if [ ! -e postgresplus-8.4.1-2-linux$archfilestring.bin ]; then # installer not found in local folder
    echo "One-click installer is about to be downloaded."
    wget http://get.enterprisedb.com/ga/postgresplus-8.4.1-2-linux$archfilestring.bin
  fi
  chmod a+x postgresplus-8.4.1-2-linux$archfilestring.bin
# Note: apparently only the One-click installer contains postgis built in.
#  No postgis.sql file is provided with the installers found here:
# http://www.enterprisedb.com/downloads/postgres-postgresql-downloads
# PostgreSQL 9.0 * (31-Jan-11)   file: postgresql-9.0.3-1-linux-x64.bin
# The Postgres Plus Standard Server requires to register.

  echo "Enter your sudo or root password to execute the following command:"
  echo "$installdir/postgresplus-8.4.1-2-linux$archfilestring.bin --enable-components dbserver,postgis --disable-components slony,pgJdbc,psqlOdbc,npgsql,pgbouncer,pgmemcache,pgagent --prefix $installdir --datadir $datadir --serverport $port --mode unattended --unattendedmodeui minimal"

  if [ -z `which sudo` ]; then
    # 'sudo' does not exist. We are probably not on Ubuntu, we can su root
    su - root -c "$installdir/postgresplus-8.4.1-2-linux$archfilestring.bin  \
      --enable-components dbserver,postgis --disable-components  \
      slony,pgJdbc,psqlOdbc,npgsql,pgbouncer,pgmemcache,pgagent --prefix $installdir  \
      --datadir $datadir --serverport $port --mode unattended --unattendedmodeui  \
      minimal"
  else
    # 'sudo' exists (we may be on Ubuntu)
    sudo -k $installdir/postgresplus-8.4.1-2-linux$archfilestring.bin  \
      --enable-components dbserver,postgis --disable-components  \
      slony,pgJdbc,psqlOdbc,npgsql,pgbouncer,pgmemcache,pgagent --prefix $installdir  \
      --datadir $datadir --serverport $port --mode unattended --unattendedmodeui  \
      minimal
  fi

# Add new psql to the path. Thanks tahongawaka for pointing the need for this.
# See discussion at https://sourceforge.net/projects/osm2postgresql/forums/forum/1683571/topic/4507607
if  [ -z "$bash_init_script" ] ; then
    bash_init_script=~/.bashrc # use default value
fi
echo "Postgres server installed. Adding the path to '$installdir/bin/psql' in $bash_init_script"
touch $bash_init_script # make sure the file exists
echo "" >> $bash_init_script # add an empty line
echo "PATH=$installdir/bin:\$PATH; export PATH" >> $bash_init_script
echo "The file '$bash_init_script' now contains the following code related to the PATH:"
cat  $bash_init_script | grep PATH


echo "Will create database $dbname now."
echo "You will be asked the current postgres password now."
echo "Please type 'postgres' (without quotes)."
echo "-- BEGIN; CREATE USER `whoami`; ALTER USER `whoami` SUPERUSER;
ALTER USER `whoami` WITH PASSWORD '`whoami`' ; -- COMMIT;
CREATE DATABASE \"$dbname\" WITH OWNER `whoami` TEMPLATE template_postgis;
  \\c $dbname
  \\i $installdir/share/postgresql/contrib/hstore.sql
  " | ${psql_folder}psql $pgconnect_postgres -d postgres postgres --echo-queries --echo-hidden
fi



if [[ ( "$install" = "no" ) && ( "$createdb"="yes" ) ]]; then
  echo "Will try to create the database '$dbname'"
  echo $pgconnect_postgres
  echo "CREATE DATABASE \"$dbname\" WITH OWNER = `whoami`;" | ${psql_folder}psql $pgconnect_postgres --echo-queries

  if [ ! -z "$tablespace" ] ; then # Create tablespace. Folder MUST be owned by postgres (this is a postgresql limitation)
    mkdir -p ${datadir%/*} # create parent directory (does not complain if already exists)
    mkdir $datadir # will exit with error if fails or already exists

    echo "Please enter your sudo or root password to create tablespace:"
    if [ -z `which sudo` ]; then
      su - root -c "chown postgres:postgres $datadir"
    else
      sudo -k chown postgres:postgres $datadir
    fi

    echo "CREATE TABLESPACE $tablespace OWNER `whoami` LOCATION '$datadir'; \
     ALTER DATABASE $dbname SET TABLESPACE $tablespace;" | ${psql_folder}psql $pgconnect_postgres
  fi

  # Test if plpgsql is installed (should be true in postgresql 9.0 and false in 8.4, by default)
  plpgsql_installed=`echo "SELECT 'plpgsql_is_installed'::varchar FROM pg_language WHERE lanname='plpgsql';" \
    | ${psql_folder}psql $pgconnect_user $dbname | grep plpgsql_is_installed | sed 's/ //g'`

  if [ "$plpgsql_installed" == "plpgsql_is_installed" ]; then
      echo "plpgsql is already installed"
    else
      createlang  $pgconnect_user plpgsql $dbname
  fi

  ${psql_folder}psql  $pgconnect_user --file $postgisfolder/postgis.sql $dbname
  ${psql_folder}psql  $pgconnect_user --file $postgisfolder/spatial_ref_sys.sql
  ${psql_folder}psql  $pgconnect_user --file $hstorefolder/hstore.sql

fi


# TODO : use new functions of osmosis-0.39 if useful
# # do not get the latest by default as the osmosis team does not support backward compatibility
# if [[ ! -f osmosis-latest.tgz ]]; then
#   wget http://dev.openstreetmap.org/~bretth/osmosis-build/osmosis-latest.tgz
# fi
# tar -xzf osmosis-latest.tgz
## Both of those should extract the name of the folder extracted above
# osmosis_version=`ls -d -1 --group-directories-first -r  osmosis-* | head -n 1`
# osmosis_version=`tar -ztvf osmosis-latest.tgz | head -n 1 | sed 's/[^o]\+//' | sed 's_/.\+$__'`
# echo $osmosis_version


if [[ ! -f osmosis-0.38.tgz ]]; then
  wget http://dev.openstreetmap.org/~bretth/osmosis-build/osmosis-0.38.tgz
fi
tar -xzf osmosis-0.38.tgz
# Both of those should extract the name of the folder extracted above
osmosis_version=osmosis-0.38
echo $osmosis_version


# worked with osmosis 0-38. Script names have changed...
${psql_folder}psql $pgconnect_user -f ./$osmosis_version/script/pgsql_simple_schema_0.6.sql  -d $dbname
${psql_folder}psql $pgconnect_user -f ./$osmosis_version/script/pgsql_simple_schema_0.6_bbox.sql  -d $dbname
${psql_folder}psql $pgconnect_user -f ./$osmosis_version/script/pgsql_simple_schema_0.6_linestring.sql  -d $dbname

# might work with osmosis 0-39...
# ${psql_folder}psql $pgconnect_user -f ./$osmosis_version/script/pgsimple_schema_0.6.sql  -d $dbname
# ${psql_folder}psql $pgconnect_user -f ./$osmosis_version/script/pgsimple_schema_0.6_bbox.sql  -d $dbname
# ${psql_folder}psql $pgconnect_user -f ./$osmosis_version/script/pgsimple_schema_0.6_linestring.sql  -d $dbname

execdir=`pwd`
echo "Will create temporarydir $temporarydir"
date +"%Y-%m-%d_%H:%M:%S"
echo "Time: Starting import with Osmosis at `date +"%Y-%m-%d_%H:%M:%S"`"
mkdir $temporarydir
./$osmosis_version/bin/osmosis -v --read-xml file="$osmfile" --buffer --write-pgsql-dump directory="$temporarydir" 
cd $temporarydir
${psql_folder}psql $pgconnect_user -f $execdir/$osmosis_version/script/pgsql_simple_load_0.6.sql  -d $dbname

date +"%Y-%m-%d_%H:%M:%S"
echo "Time: Finished import with Osmosis at `date +"%Y-%m-%d_%H:%M:%S"`"



cd $execdir

# for debugging:
# ${psql_folder}psql $pgconnect_user  -d $dbname --echo-queries
${psql_folder}psql $pgconnect_user  -d $dbname  <<- _EOF_
COMMENT ON DATABASE $dbname IS 'Created $NOW with $version; powered by Osmosis $osmosis_version';
-- DROP TABLE nodes_with_tags
CREATE TABLE nodes_with_tags AS (SELECT *, NULL::text as class FROM nodes WHERE cast (tags as text) !='');
ALTER TABLE nodes_with_tags ADD COLUMN idint4 int4;
UPDATE nodes_with_tags SET idint4 = id;
CREATE UNIQUE INDEX idx_nodes_idint4 ON nodes_with_tags (idint4);
ALTER TABLE nodes_with_tags RENAME COLUMN tags TO tagshstore;
ALTER TABLE nodes_with_tags ADD COLUMN tags text;
UPDATE nodes_with_tags SET tags = regexp_replace(tagshstore::text, '=>', '=', 'g');
CREATE INDEX idx_nodes_with_tags_geom  ON nodes_with_tags USING gist (geom);

INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column,
  coord_dimension, srid, "type")
SELECT '', 'public', 'nodes_with_tags', 'geom', ST_CoordDim(geom), ST_SRID(geom), GeometryType(geom)
FROM public.nodes_with_tags LIMIT 1;
-- http://postgis.refractions.net/docs/ch04.html#Manual_Register_Spatial_Column

-- Delete nodes that have only no informative tags
DELETE FROM nodes_with_tags 
WHERE idint4 IN (
  SELECT idint4 FROM nodes_with_tags
  WHERE (tags like '%"source"=%'
  or  tags like '%"created_by"=%'
  or  tags like '%"converted_by"=%')
  and array_upper(avals(tagshstore), 1) = 1
 -- length of the hstore=1
);

DELETE FROM nodes_with_tags 
WHERE idint4 IN (
  SELECT idint4 FROM nodes_with_tags
  WHERE ((tags like '%"source"=%' AND tags like '%"created_by"=%')
OR (tags like '%"source"=%' AND tags like '%"converted_by"=%')
OR (tags like '%"created_by"=%' AND tags like '%"converted_by"=%')
)
  and array_upper(avals(tagshstore), 1) = 2
 -- length of the hstore=2
);
_EOF_

## Reproject the geometries if asked by user
if [ ! "$EPSG" = "do_not_reproject" ]; then
echo "Time: Starting reprojection at `date +"%Y-%m-%d_%H:%M:%S"`"
  ${psql_folder}psql $pgconnect_user  -d $dbname  <<- _EOF_
  UPDATE nodes_with_tags SET geom = ST_SetSRID(ST_Transform(geom, $EPSG), $EPSG);
  ALTER TABLE ways drop constraint enforce_srid_bbox;
  ALTER TABLE ways drop constraint enforce_srid_linestring;
  UPDATE ways SET linestring = ST_SetSRID(ST_Transform(linestring, $EPSG), $EPSG);
  UPDATE ways SET bbox = ST_SetSRID(ST_Transform(bbox, $EPSG), $EPSG);
  SELECT Populate_Geometry_Columns(); -- update geometry_columns after all reprojections

-- TODO (to check): According to QGIS:
-- epsg:9OO913  +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +over +no_defs
-- epsg:3785  +proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs
_EOF_
fi
echo "Time: Finished reprojection at `date +"%Y-%m-%d_%H:%M:%S"`"

${psql_folder}psql $pgconnect_user  -d $dbname  <<- _EOF_
ALTER TABLE ways ADD COLUMN idint4 int4;
UPDATE ways SET idint4 = id;
CREATE UNIQUE INDEX idint4idx ON ways (idint4);
ALTER TABLE ways RENAME COLUMN tags TO tagshstore;
ALTER TABLE ways ADD COLUMN tags text;
-- TODO: in bash, not SQL
-- echo "Time: (`date +"%Y-%m-%d_%H:%M:%S"`) Converting tags from hstore to text "
UPDATE ways SET tags = regexp_replace(tagshstore::text, '=>', '=', 'g');

ALTER TABLE ways ADD COLUMN name text;
ALTER TABLE nodes_with_tags ADD COLUMN name text;
UPDATE nodes_with_tags SET name = tagshstore -> 'name' WHERE tagshstore ? 'name';
UPDATE ways SET name = tagshstore -> 'name' WHERE tagshstore ? 'name';



-- -- -- -- -- --
--  POLYGONS - --
-- -- -- -- -- --
-- CREATE TABLE WITH POLYGONS MADE OF A SINGLE LINESTRING
-- DROP TABLE simple_polys;
CREATE TABLE simple_polys AS(
  SELECT  idint4,
    ST_MakePolygon(linestring) as polygon,
    regexp_replace(tags::text, '=>', '=', 'g')  as tags,
    tagshstore,
    area(ST_MakePolygon(linestring)) as area -- TODO: convert into metric system (or better do it on projected, metric data, processing eveything after reprojection)
  FROM ways
  WHERE IsClosed(linestring)
    and NPoints(linestring) > 3
-- new in version 0.2
--    and idint4 not in (SELECT member_id FROM relation_members WHERE member_role = 'outer')
);
CREATE UNIQUE INDEX idx_idint4_simple_polys ON simple_polys (idint4);


-- ADD polygons to TABLE relations
ALTER TABLE relations ADD COLUMN idint4 int4;
UPDATE relations SET idint4 = id::int4;
CREATE UNIQUE INDEX idx_idint4 ON relations (idint4);

ALTER TABLE relations RENAME COLUMN tags TO tagshstore;
ALTER TABLE relations ADD COLUMN tags text;
UPDATE relations SET tags = regexp_replace(tagshstore::text, '=>', '=', 'g');

-- ALTER TABLE relations DROP COLUMN outerring_array;
-- ALTER TABLE relations DROP COLUMN outerring_linestring;
-- ALTER TABLE relations DROP COLUMN outerring;
ALTER TABLE relations ADD COLUMN outerring_linestring geometry;
ALTER TABLE relations ADD COLUMN outerring_array int4[];
ALTER TABLE relations ADD COLUMN outerring geometry;

-- ALTER TABLE relations DROP COLUMN innerring_linestring;
ALTER TABLE relations ADD COLUMN innerring_linestring geometry[];

-- ALTER TABLE relations DROP COLUMN polygon;
ALTER TABLE relations ADD COLUMN polygon geometry;

-- create an ARRAY of all outerrings
UPDATE relations SET outerring_array = (
  SELECT  array_agg( r1.member_id) as array1
  FROM relation_members r1, ways
  WHERE r1.member_role = 'outer'
    and r1.relation_id = relations.id
    and ways.idint4 = r1.member_id
    and NPoints(ways.linestring) > 1 and IsValid(ways.linestring)
  GROUP BY r1.relation_id
);

-- create outerring linestring (not checked if valid yet)
UPDATE relations SET outerring_linestring = (
  SELECT   ST_LineMerge(ST_Collect(ways.linestring))
  FROM relation_members r1, ways
  WHERE r1.member_role = 'outer'
  and r1.relation_id = relations.id
  and 
  NPoints(ways.linestring) > 1 and IsValid(ways.linestring) 
  and ways.idint4 = r1.member_id
  GROUP BY r1.relation_id
);

-- create innerrings linestrings (not checked if valid yet)
UPDATE relations SET innerring_linestring = (
    ARRAY(
	  SELECT ST_LineMerge(ST_Collect(linestring)) as inner_ring FROM ways WHERE ways.idint4  IN
	    (SELECT member_id FROM relation_members r1
		WHERE r1.relation_id = relations.idint4 and r1.member_role = 'inner'
	    )
	)
  )
  WHERE array_length(ARRAY(
	  SELECT ST_LineMerge(ST_Collect(linestring)) as inner_ring FROM ways WHERE ways.idint4  IN
	    (SELECT member_id FROM relation_members r1
		WHERE r1.relation_id = relations.idint4 and r1.member_role = 'inner'
	    )
	),1) >0 --check that there is at least one inner line
;

-- ALTER TABLE relations DROP COLUMN poly_type;
ALTER TABLE relations ADD COLUMN poly_type text;

UPDATE relations SET poly_type= 'unknown';

-- a ring with only 3 points is flat: A-B-A (1st point = 3rd point), hence buggy
UPDATE relations SET poly_type= 'no valid outerring' WHERE 
NPoints(outerring_linestring) < 4 -- 5 relations are buggy in italy.osm
or outerring_linestring IS NULL -- about 16000 (relations between simple nodes?)
; 
-- the above must be done before what follows, because if less than 3 points, test may crash
UPDATE relations SET poly_type= 'no valid outerring' WHERE 
poly_type = 'unknown'
and NOT IsClosed( outerring_linestring); -- 136 are buggy in italy.osm

UPDATE relations SET poly_type= 'no valid outerring' WHERE 
poly_type = 'unknown'
and NOT IsSimple( outerring_linestring); -- 102 more are buggy in italy.osm


-- If (NOT poly_type= 'no valid outerring') after the above, it means there is a valid outerring. Now, let us see if there is a valid inerring (or several)

-- if there is no inner line, there is no valid inerring
UPDATE relations SET poly_type= 'no valid inerring'
WHERE poly_type = 'unknown'
and innerring_linestring IS NULL
; -- 3015 more have no valid inerring

-- innering must be closed
UPDATE relations SET poly_type= 'no valid inerring'
WHERE poly_type = 'unknown'
and (NOT ISClosed(ST_LineMerge(ST_Collect(innerring_linestring ))))
; -- 44 more are buggy

-- innering must be big enough
-- FIXME: this checks that all the innerings together have more than 3 points, not that each innering is valid
UPDATE relations SET poly_type= 'no valid inerring'
WHERE poly_type = 'unknown'
and NPoints(ST_LineMerge(ST_Collect(innerring_linestring ))) <4
; 



-- check further validity of innerring: closed and big enough
-- however, if there are several holes and only one is too small, the test based on NPoints()
-- will not be sensitive enough (such wrong relations are probably extremely rare; none found in italy.osm).
-- FIXME: is this still necessary after the tests above?
UPDATE relations SET poly_type= 'valid innerring'
WHERE poly_type = 'unknown'
and ( ISClosed(ST_LineMerge(ST_Collect(innerring_linestring ))))
and NPoints(ST_LineMerge(ST_Collect(innerring_linestring ))) > 3
; 

-- SELECT id,poly_type FROM relations WHERE ISClosed(ST_LineMerge(ST_Collect(innerring_linestring ))) and NPoints(ST_LineMerge(ST_Collect(innerring_linestring )))=3; --should give no result if OSM data were perfect; not the case (2 results for italy.osm).

-- TODO: try to collect the tags FROM the rings and assign them to the relation if relevant

UPDATE relations SET polygon = 
ST_MakePolygon(outerring_linestring, (innerring_linestring ))
WHERE poly_type= 'valid innerring'
and GeometryType(outerring_linestring) ='LINESTRING';

-- the complex polygons that are valid no longer need to be represented with their outerring only
-- and not deleting those simple_polys will prevent insertion in the final polygon UNION below
DELETE FROM simple_polys WHERE simple_polys.idint4 IN (SELECT member_id FROM relation_members WHERE member_role='outer' and relation_id IN
(SELECT id FROM relations WHERE poly_type='valid innerring' and ST_IsValid(polygon)
)
);

DELETE FROM ways WHERE ways.idint4 IN (SELECT member_id FROM relation_members WHERE member_role='outer' and relation_id IN
(SELECT id FROM relations WHERE poly_type='valid innerring' and ST_IsValid(polygon))
);

-- Also clean useless innerrings stored as simple_polys or ways
DELETE FROM simple_polys WHERE simple_polys.idint4 IN (
  SELECT member_id FROM relation_members WHERE member_role='inner' and relation_id IN
    (SELECT id FROM relations WHERE poly_type='valid innerring' and ST_IsValid(polygon))
  )
and akeys(tagshstore)::text='{}'
;

DELETE FROM ways WHERE ways.idint4 IN (
  SELECT member_id FROM relation_members WHERE member_role='inner' and relation_id IN
    (SELECT id FROM relations WHERE poly_type='valid innerring' and ST_IsValid(polygon))
  )
and akeys(tagshstore)::text='{}'
;


-- new in version 0.2: was (wrongly) earlier in the script
-- Create simple polygon not having (valid) innering(s)
UPDATE relations SET polygon = MakePolygon(outerring_linestring)
WHERE (poly_type = 'no valid inerring'
OR poly_type = 'unknown')
--   and id=1309665
and GeometryType((outerring_linestring)) ='LINESTRING'
;


--Disaggregate multilines into linestrings, one per row
DROP TABLE if exists dumped_multilinestring;
CREATE TABLE dumped_multilinestring AS (
SELECT relations.id as relation_id, tags, tagshstore,
  generate_series(1,(Select ST_NumGeometries(outerring_linestring))) as lineseq,
  ST_GeometryN(outerring_linestring, generate_series(1, ST_NumGeometries (outerring_linestring))) AS outerring_linestring
 FROM relations
  WHERE GeometryType(outerring_linestring) ='MULTILINESTRING' --anyway the query would not give any 'LINESTRING'
);

-- CREATE UNIQUE INDEX idx_dumped_multilinestring_idint4 ON dumped_multilinestring (idint4);
CREATE INDEX idx_dumped_multilinestring_relation_id ON dumped_multilinestring (relation_id);

ALTER TABLE dumped_multilinestring ADD COLUMN outerring_polygon geometry;
UPDATE dumped_multilinestring SET outerring_polygon = MakePolygon(outerring_linestring)
  WHERE isclosed(outerring_linestring);
ALTER TABLE dumped_multilinestring ADD COLUMN idint4 int4;
UPDATE dumped_multilinestring SET idint4 = relation_id*1000 + lineseq; --*might* create duplicate id if more than 999 linestrings in a single multilinestring AND if bad luck


INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type") (SELECT  ''::text, 'public'::text, 'dumped_multilinestring'::text, 'outerring_polygon'::text, 2::integer, 4326::integer, 'GEOMETRY'::text FROM dumped_multilinestring limit 1);

-- TODO: add other rows in geometry_columns

-- Delete polygons from simple_polys that are also stored in dumped_multilinestring and have essentially similar or less informative tags
DELETE FROM simple_polys WHERE simple_polys.idint4 IN (
SELECT  s.idint4
FROM simple_polys s, relation_members, dumped_multilinestring m
WHERE  s.idint4 = relation_members.member_id AND
  m.relation_id = relation_members.relation_id
and  (array_length(akeys(s.tagshstore),1)  < array_length(akeys(m.tagshstore),1) OR akeys(s.tagshstore)::text='{}')
and relation_members.member_role ='outer' -- keep a simple polygon if it is just an inner in multilinestring
and (
-- array_length(akeys(s.tagshstore),1) =0  is not true when tagshstore is empty
akeys(s.tagshstore)::text='{}'
OR s.tagshstore -> 'natural' = m.tagshstore -> 'natural' -- sometimes the tags for the simple_polys are quite different; this tries to exclude those by testing that the values is the same for at least one of the 3 follwing keys
OR s.tagshstore -> 'landuse' = m.tagshstore -> 'building'
OR s.tagshstore -> 'landuse' = m.tagshstore -> 'building')
group by s.idint4 )
;

-- Put all polygons in a single table
DROP TABLE IF EXISTS polygons ;
CREATE TABLE polygons AS ( 
  SELECT idint4, tags, tagshstore, polygon, id as relation_id, NULL::text as class  FROM relations
 UNION ALL
  SELECT idint4, tags, tagshstore, polygon, NULL::int4  as relation_id, NULL::text as class  FROM simple_polys
 UNION ALL
  SELECT idint4, tags, tagshstore, outerring_polygon, relation_id, NULL::text as class  FROM dumped_multilinestring
);
CREATE UNIQUE INDEX idx_polygons ON polygons (idint4); -- I think the above guarantees uniqueness but I am unsure (is it necessary to chech whether relation ids overlap with ways id?). No problem for italy.osm

ALTER TABLE polygons ADD COLUMN name text;
UPDATE polygons SET name= tagshstore -> 'name' WHERE exist(tagshstore,'name')
;


-- INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type") (SELECT  ''::text, 'public'::text, 'polygons'::text, 'polygon'::text, 2::integer, 4326::integer, 'GEOMETRY'::text FROM polygons limit 1);

SELECT Populate_Geometry_Columns(); -- update geometry_columns


ALTER TABLE polygons ADD COLUMN area float;
UPDATE polygons SET area=ST_Area(polygon);

-- To speedup reading tags (hstore has index support for @> and ? operators)
CREATE INDEX ways_tagshstore_idx ON ways USING GIST(tagshstore);

-- ALTER TABLE ways DROP COLUMN isarea;
ALTER TABLE ways ADD COLUMN isarea boolean;
ALTER TABLE ways ADD COLUMN isclosed boolean;
UPDATE ways SET isclosed = true WHERE  IsClosed("linestring");

UPDATE ways SET isarea = false
WHERE isclosed=true and isarea IS NULL
and NOT (tagshstore @> 'area=>yes')
and (
tagshstore @> 'area=>no'
OR (tagshstore ? 'highway' and not(tagshstore @> 'highway=>services')) -- different from highway=>service WITHOUT 's'
OR tagshstore @> 'junction=>roundabout'
OR tagshstore ? 'barrier'
);


UPDATE ways SET isarea = true
WHERE isclosed=true and
isarea IS NULL
and NOT (tagshstore @> 'area=>no')
and (
-- tagshstore -> 'area' ='yes' -- might be slow
-- the following uses the index if exists
tagshstore @> 'area=>yes'
OR tagshstore @> 'amenity=>parking'
OR tagshstore @> 'building=>yes'
OR (tagshstore ? 'building' AND NOT(tagshstore @> 'building=>no'))
OR tagshstore @> 'aeroway=>aerodrome'
OR tagshstore @> 'waterway=>riverbank'
or tagshstore @> 'highway=>services'
OR tagshstore @> 'place=>suburb'
OR tagshstore ? 'landuse'
OR tagshstore ? 'wood'
OR tagshstore ? 'place'
OR tagshstore ? 'leisure' -- could this wrongly classify a closed 'leisure' track?
OR tagshstore ? 'amenity'
-- OR tagshstore ? ''
OR tagshstore ? 'sport'  -- this might wrongly classify a closed sport track
OR (tagshstore ? 'natural' AND NOT (tagshstore @> 'natural=>coastline'))
OR tagshstore @> 'power=>station'
 -- all closed natural ways are areas, with the (rare?) exception of circular cliff (which must have area=>no) or very small islands as single-way/closed coastline
-- OR tagshstore @> '=>'
)
;

-- known closed ways that are not areas:
--  "junction"="roundabout"
DELETE FROM  ways WHERE isarea = true
and idint4 in (SELECT idint4 FROM polygons);

-- Extracting a small area from a large .osm file with osmosis 0.38 does cut some (all?) polygons and leave them without some of the children nodes. You will see it if you do the following SELECT at this point:
-- SELECT id, tagshstore, nodes,NPOINTS(linestring), ST_asEWKT(linestring) from ways WHERE  isarea = true and NPOINTS(linestring)=3; -- note: complains if you do not filter  NPOINTS(linestring)=3, try this:
-- SELECT id, tagshstore, nodes,NPOINTS(linestring) from ways WHERE  isarea = true
-- here is how to remove those (destroyed) polygons
DELETE FROM  ways WHERE isarea = true and NPOINTS(linestring)<4;
-- Normally at this point, the following query should not return any row. Otherwise please add here or above the SQL code to manage those cases.
-- SELECT * FROM  ways WHERE isarea = true ;
-- those polygons might be there for the same reason:
DELETE FROM  ways WHERE NPOINTS(linestring)<2;
-- SELECT count(id) FROM  ways WHERE NPOINTS(linestring)=1 ;
-- Note that with old postgis it is not possible to do:
-- SELECT id FROM  ways WHERE not isvalid(linestring) ;
-- because of bug: http://trac.osgeo.org/postgis/ticket/408



-- Create a "class" field for easy rendering with GIS software (based on a single field)
-- Note: QGIS's rule-based renderer can use complex queries at the style level with no need for this
-- See http://www.qgis.org/wiki/Using_OpenStreetMap_data
-- and http://trac.osgeo.org/qgis/ticket/3222
-- This is provided as a convenience for the user. This is still beta quality but should be useful.
-- ALTER TABLE nodes_with_tags ADD COLUMN class text;
-- ALTER TABLE polygons ADD COLUMN class text;

ALTER TABLE ways ADD COLUMN class text;
 UPDATE ways  SET class='aerialway' WHERE class IS NULL AND tags like '%aerialway%' ;
 UPDATE ways  SET class='coastline' WHERE class IS NULL AND tags like '%"natural"="coastline"%' ;
 UPDATE ways  SET class='ferry' WHERE class IS NULL AND tags like '%ferry%' ;
 UPDATE ways  SET class='footway' WHERE class IS NULL AND tags like '%"highway"="footway"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='motorway' WHERE class IS NULL AND tags like '%"highway"="motorway"%'  AND NOT (tags like '%"tunnel"="yes"%') AND NOT (tags like '%"bridge"="yes"%') ;
 UPDATE ways  SET class='motorway (bridge)' WHERE class IS NULL AND tags like '%"highway"="motorway"%'  AND NOT (tags like '%"tunnel"="yes"%') AND (tags like '%"bridge"="yes"%') ;
 UPDATE ways  SET class='motorway link' WHERE class IS NULL AND tags like '%"highway"="motorway_link"%'  AND NOT (tags like '%"tunnel"="yes"%') AND NOT (tags like '%"bridge"="yes"%') ;
 UPDATE ways  SET class='motorway link' WHERE class IS NULL AND tags like '%"highway"="motorway_link"%'  AND NOT (tags like '%"tunnel"="yes"%') AND (tags like '%"bridge"="yes"%') ;
 UPDATE ways  SET class='national park' WHERE class IS NULL AND tags like '%"boundary"="national_park"%' ;
 UPDATE ways  SET class='path' WHERE class IS NULL AND tags like '%"highway"="path"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='pedestrian highway' WHERE class IS NULL AND tags like '%"highway"="pedestrian"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='power line' WHERE class IS NULL AND tags like '%"power"="%line"%' ;
 UPDATE ways  SET class='primary highway' WHERE class IS NULL AND tags like '%"highway"="primary"%' AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='rail' WHERE class IS NULL AND tags like '%"railway"="rail"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='rail' WHERE class IS NULL AND tags like '%"railway"="rail"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='residential highway' WHERE class IS NULL AND tags like '%"highway"="residential"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='road' WHERE class IS NULL AND tags like '%"highway"="road"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='secondary highway' WHERE class IS NULL AND tags like '%"highway"="secondary"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='service highway' WHERE class IS NULL AND tags like '%"highway"="service"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='steps' WHERE class IS NULL AND tags like '%"highway"="steps"%' ;
 UPDATE ways  SET class='tertiary highway' WHERE class IS NULL AND ((tags like '%"highway"="tertiary"%') OR (tags like '%"highway"="tertiary_link"%')) AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='grade-5 track' WHERE class IS NULL AND tags like '%"highway"="track"%' AND tags like '%"tracktype"="grade5"%' ;
 UPDATE ways  SET class='grade-4 track' WHERE class IS NULL AND tags like '%"highway"="track"%' AND tags like '%"tracktype"="grade4"%' ;
 UPDATE ways  SET class='grade-3 track' WHERE class IS NULL AND tags like '%"highway"="track"%' AND tags like '%"tracktype"="grade3"%' ;
 UPDATE ways  SET class='grade-2 track' WHERE class IS NULL AND tags like '%"highway"="track"%' AND tags like '%"tracktype"="grade2"%' ;
 UPDATE ways  SET class='grade-1 track' WHERE class IS NULL AND tags like '%"highway"="track"%' AND tags like '%"tracktype"="grade1"%' ;
 UPDATE ways  SET class='track' WHERE class IS NULL AND tags like '%"highway"="track"%' AND NOT (tags like '%"tracktype"="grade"%') ;
 UPDATE ways  SET class='unclassified highway' WHERE class IS NULL AND tags like '%"highway"="unclassified"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='river' WHERE class IS NULL AND tags like '%"waterway"="river"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='stream' WHERE class IS NULL AND tags like '%"waterway"="stream"%'  AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='waterway' WHERE class IS NULL AND (tags like '%"waterway"%' OR (tags like '%"water"%')) AND NOT (tags like '%"stream"%') ;
 UPDATE ways  SET class='tunnel' WHERE class IS NULL AND tags like '%"tunnel"="yes"%' ;
 UPDATE ways  SET class='level 1 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="1"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 2 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="2"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 3 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="3"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 4 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="4"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 5 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="5"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 6 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="6"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 7 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="7"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 8 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="8"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 9 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="9"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='level 0 admin. boundary' WHERE class IS NULL AND tags like '%"boundary"="administrative"%' and (tags like '%"admin_level"="10"%') and not (tags like '%coastline%') ;
 UPDATE ways  SET class='trunk' WHERE class IS NULL AND tags like '%"highway"="trunk"%' AND NOT (tags like '%"tunnel"="yes"%') ;
 UPDATE ways  SET class='cycleway' WHERE class IS NULL AND tags like '%"highway"="cycleway"%' ;
 UPDATE ways  SET class='trunk link' WHERE class IS NULL AND tags like '%"highway"="trunk_link"%' ;
 UPDATE ways  SET class='primary link' WHERE class IS NULL AND tags like '%"highway"="primary_link"%' ;
 UPDATE ways  SET class='secondary link' WHERE class IS NULL AND tags like '%"highway"="secondary_link"%' ;
 UPDATE ways  SET class='airplane taxiway' WHERE class IS NULL AND tags like '%"aeroway"="taxiway"%' ;
 UPDATE ways  SET class='runway' WHERE class IS NULL AND tags like '%"aeroway"="runway"%' ;
 UPDATE ways  SET class='living street' WHERE class IS NULL AND tags like '%"highway"="living_street"%' ;
 UPDATE ways  SET class='motorway in construction' WHERE class IS NULL AND tags like '%"construction"%' and tags like '%"motorway"%' ;
 UPDATE ways  SET class='highway in construction' WHERE class IS NULL AND tags like '%"construction"%' and NOT (tags like '%"motorway"%') ;
 UPDATE ways  SET class='fence' WHERE class IS NULL AND tags like '%"barrier"="fence"%'  ;
 UPDATE ways  SET class='hedge' WHERE class IS NULL AND tags like '%"barrier"="hedge"%'  ;
 UPDATE ways  SET class='wall' WHERE class IS NULL AND tags like '%"barrier"="%wall"%'  ;
 UPDATE ways  SET class='pier' WHERE class IS NULL AND tags like '%"man_made"="pier"%'  ;
 UPDATE ways  SET class='railway' WHERE class IS NULL AND tags like '%"railway"%'  AND NOT (tags like '%"rail"%')   AND NOT (tags like '%"platform"%')    ;
 UPDATE ways  SET class='building' WHERE class IS NULL AND tags like '%"building"%' ;
 UPDATE ways  SET class='residential' WHERE class IS NULL AND tags like '%"landuse"="residential"%' ;
 UPDATE ways  SET class='parking' WHERE class IS NULL AND tags like '%"parking"%' ;
 UPDATE ways  SET class='industrial' WHERE class IS NULL AND tags like '%"landuse"="industrial"%' ;
 UPDATE ways  SET class='downhill piste' WHERE class IS NULL AND tags like '%"piste:type"="downhill"%' ;
 UPDATE ways  SET class='cliff' WHERE class IS NULL AND tags like '%"cliff"%' ;
 UPDATE nodes_with_tags SET class='cash dispenser' WHERE class IS NULL AND tags like '%"atm"%' ;
 UPDATE nodes_with_tags SET class='bank' WHERE class IS NULL AND tags like '%"bank"%' ;
 UPDATE nodes_with_tags SET class='bench' WHERE class IS NULL AND tags like '%"bench%' ;
 UPDATE nodes_with_tags SET class='buoy' WHERE class IS NULL AND tags like '%buoy%' ;
 UPDATE nodes_with_tags SET class='bus stop' WHERE class IS NULL AND tags like '%"bus_stop%' ;
 UPDATE nodes_with_tags SET class='bus station' WHERE class IS NULL AND tags like '%bus_station%' ;
 UPDATE nodes_with_tags SET class='bar' WHERE class IS NULL AND  tags like '%"bar"%' ;
 UPDATE nodes_with_tags SET class='cafe' WHERE class IS NULL AND tags like '%cafe%'  ;
 UPDATE nodes_with_tags SET class='drinking water' WHERE class IS NULL AND tags like '%drinking_water%' ;
 UPDATE nodes_with_tags SET class='fast food' WHERE class IS NULL AND tags like '%fast_food%' ;
 UPDATE nodes_with_tags SET class='fountain' WHERE class IS NULL AND tags like '%fountain%' ;
 UPDATE nodes_with_tags SET class='lpg fuel' WHERE class IS NULL AND tags like '%"amenity"="fuel"%' and tags like '%"fuel:lpg"="yes"%' ;
 UPDATE nodes_with_tags SET class='cemetery' WHERE class IS NULL AND tags like '%grave_yard%' OR tags like '%cemetery%' ;
 UPDATE nodes_with_tags SET class='hospital (incl. emergency)' WHERE class IS NULL AND tags like '%hospital%' and tags like '%"emergency"="yes"%'  ;
 UPDATE nodes_with_tags SET class='hospital' WHERE class IS NULL AND tags like '%hospital%' ;
 UPDATE nodes_with_tags SET class='ice cream shop' WHERE class IS NULL AND tags like '%ice_cream%' ;
 UPDATE nodes_with_tags SET class='parking (with fee)' WHERE class IS NULL AND tags like '%"amenity"="parking"%' and tags like '%"fee"="yes"%'  ;
 UPDATE nodes_with_tags SET class='pharmacy' WHERE class IS NULL AND tags like '%pharmacy%' ;
 UPDATE nodes_with_tags SET class='police' WHERE class IS NULL AND tags like '%"police"%' ;
 UPDATE nodes_with_tags SET class='post box' WHERE class IS NULL AND tags like '%post_box%' ;
 UPDATE nodes_with_tags SET class='post office' WHERE class IS NULL AND tags like '%post_office%' ;
 UPDATE nodes_with_tags SET class='recycling' WHERE class IS NULL AND tags like '%"recycling%' ;
 UPDATE nodes_with_tags SET class='restaurant' WHERE class IS NULL AND tags like '%restaurant%' ;
 UPDATE nodes_with_tags SET class='shelter (with fireplace)' WHERE class IS NULL AND  tags like '%"amenity"="shelter"%' and tags like '%"fireplace"="yes"%' ;
 UPDATE nodes_with_tags SET class='shelter' WHERE class IS NULL AND  tags like '%"amenity"="shelter"%' ;
 UPDATE nodes_with_tags SET class='taxi' WHERE class IS NULL AND tags like '%"amenity"="taxi"%' ;
 UPDATE nodes_with_tags SET class='telephone' WHERE class IS NULL AND tags like  '%"amenity"="telephone"%' ;
 UPDATE nodes_with_tags SET class='theatre' WHERE class IS NULL AND tags like '%"theatre"%' ;
 UPDATE nodes_with_tags SET class='toilets (accessible with wheelchair)' WHERE class IS NULL AND tags like '%"toilets%' AND tags like '%"wheelchair"="yes"%' ;
 UPDATE nodes_with_tags SET class='toilets' WHERE class IS NULL AND tags like '%"toilets"%' ;
 UPDATE nodes_with_tags SET class='townhall' WHERE class IS NULL AND tags like '%townhall%' ;
 UPDATE nodes_with_tags SET class='vending machine' WHERE class IS NULL AND tags like '%vending_machine%' ;
 UPDATE nodes_with_tags SET class='locality' WHERE class IS NULL AND tags like '%"place"="locality"%' ;
 UPDATE nodes_with_tags SET class='hamlet' WHERE class IS NULL AND tags like '%"place"="hamlet"%' ;
 UPDATE nodes_with_tags SET class='village' WHERE class IS NULL AND tags like '%"place"="village"%' ;
 UPDATE nodes_with_tags SET class='town' WHERE class IS NULL AND tags like '%"place"="town"%' ;
 UPDATE nodes_with_tags SET class='guidepost' WHERE class IS NULL AND tags like '%"information"="guidepost"%' ;
 UPDATE nodes_with_tags SET class='attraction' WHERE class IS NULL AND tags like '%"tourism"="attraction"%' ;
 UPDATE nodes_with_tags SET class='camp site' WHERE class IS NULL AND tags like '%"tourism"="camp_site"%' ;
 UPDATE nodes_with_tags SET class='guest house' WHERE class IS NULL AND tags like '%"tourism"="guest_house"%' OR tags like '%"tourism"="bed_and_breakfast"%'  ;
 UPDATE nodes_with_tags SET class='motel' WHERE class IS NULL AND tags like '%"tourism"="motel"%' ;
 UPDATE nodes_with_tags SET class='hotel' WHERE class IS NULL AND tags like '%"tourism"="hotel"%' ;
 UPDATE nodes_with_tags SET class='information office' WHERE class IS NULL AND tags like '%"information"="office"%' ;
 UPDATE nodes_with_tags SET class='information board' WHERE class IS NULL AND tags like '%"information"="board"%' ;
 UPDATE nodes_with_tags SET class='map' WHERE class IS NULL AND  tags like '%"map"%' ;
 UPDATE nodes_with_tags SET class='picnic area' WHERE class IS NULL AND tags like '%picnic%' ;
 UPDATE nodes_with_tags SET class='viewpoint' WHERE class IS NULL AND tags like '%viewpoint%' ;
 UPDATE nodes_with_tags SET class='power-related' WHERE class IS NULL AND tags like '%"power"%' ;
 UPDATE nodes_with_tags SET class='peak (&lt;500 m)' WHERE class IS NULL AND tags like '%"natural"="peak"%'  AND (tags like '%"ele"="[1-9][0-9]m*"%'  OR tags like '%"ele"="[1-4][0-9][0-9]m*"%') ;
 UPDATE nodes_with_tags SET class='peak (500 - 1000 m)' WHERE class IS NULL AND tags like '%"natural"="peak"%'  AND tags like '%"ele"="[5-9][0-9][0-9]m*"%' ;
 UPDATE nodes_with_tags SET class='peak (1000 - 1500 m)' WHERE class IS NULL AND tags like '%"natural"="peak"%'  AND tags like '%"ele"="1[0-4][0-9][0-9]m*"%' ;
 UPDATE nodes_with_tags SET class='peak (1500 - 2000 m)' WHERE class IS NULL AND tags like '%"natural"="peak"%'  AND tags like '%"ele"="1[5-9][0-9][0-9]m*"%' ;
 UPDATE nodes_with_tags SET class='peak (2000 - 3000 m)' WHERE class IS NULL AND tags like '%"natural"="peak"%'  AND tags like '%"ele"="2[0-9][0-9][0-9]m*"%' ;
 UPDATE nodes_with_tags SET class='peak (3000 - 4000 m)' WHERE class IS NULL AND tags like '%"natural"="peak"%'  AND tags like '%"ele"="3[0-9][0-9][0-9]m*"%' ;
 UPDATE nodes_with_tags SET class='peak (>4000m)' WHERE class IS NULL AND tags like '%"natural"="peak"%'  AND tags like '%"ele"="[4-8][0-9][0-9][0-9]m*"%' ;
 UPDATE nodes_with_tags SET class='peak' WHERE class IS NULL AND tags like '%"natural"="peak"%' ;
 UPDATE nodes_with_tags SET class='wayside cross' WHERE class IS NULL AND tags like '%"historic"="wayside_cross"%' ;
 UPDATE nodes_with_tags SET class='helipad' WHERE class IS NULL AND tags like '%"aeroway"="helipad"%' ;
 UPDATE nodes_with_tags SET class='building' WHERE class IS NULL AND tags like '%building%' ;
 UPDATE nodes_with_tags SET class='archaeological site' WHERE class IS NULL AND tags like '%archaeological%' ;
 UPDATE nodes_with_tags SET class='communication tower' WHERE class IS NULL AND tags like '%"tower:type"="communication"%' ;
 UPDATE nodes_with_tags SET class='bunker' WHERE class IS NULL AND tags like '%"bunker%' ;
 UPDATE nodes_with_tags SET class='ruin' WHERE class IS NULL AND tags like '%"ruin%' ;
 UPDATE nodes_with_tags SET class='castle' WHERE class IS NULL AND tags like '%castle%'  ;
 UPDATE nodes_with_tags SET class='other' WHERE class IS NULL AND (tags like '%TEMPORARYTEST%') and  NOT (tags like '%bench%') AND NOT (tags like '%housenumber%') AND NOT (tags like '%"natural"="peak"%') ;
 UPDATE nodes_with_tags SET class='alpine hut' WHERE class IS NULL AND tags like '%"alpine_hut%' ;
 UPDATE nodes_with_tags SET class='caravan site' WHERE class IS NULL AND tags like '%"tourism"="caravan_site"%'  ;
 UPDATE nodes_with_tags SET class='chalet' WHERE class IS NULL AND tags like '%"chalet%'  ;
 UPDATE nodes_with_tags SET class='hostel' WHERE class IS NULL AND tags like '%"hostel"%'  ;
 UPDATE nodes_with_tags SET class='courthouse' WHERE class IS NULL AND tags like '%"courthouse"%' ;
 UPDATE nodes_with_tags SET class='fire station' WHERE class IS NULL AND tags like '%"fire_station%' ;
 UPDATE nodes_with_tags SET class='library' WHERE class IS NULL AND  tags like '%"amenity"="library"%' ;
 UPDATE nodes_with_tags SET class='playground' WHERE class IS NULL AND tags like '%"leisure"="playground"%' ;
 UPDATE nodes_with_tags SET class='prison' WHERE class IS NULL AND tags like '%"amenity"="prison"%' ;
 UPDATE nodes_with_tags SET class='survey point' WHERE class IS NULL AND  tags like '%"survey_point%' ;
 UPDATE nodes_with_tags SET class='waste' WHERE class IS NULL AND tags like  '%"amenity"="waste_%' ;
 UPDATE nodes_with_tags SET class='cycle barrier' WHERE class IS NULL AND  tags like '%"barrier"="cycle_barrier"%' OR ( tags like '%"barrier"%' AND  tags like '%"foot"="yes"%'   AND  tags like '%"bicycle"="no"%'  ) ;
 UPDATE nodes_with_tags SET class='block' WHERE class IS NULL AND tags like '%"barrier"="block"%' ;
 UPDATE nodes_with_tags SET class='bollard' WHERE class IS NULL AND tags like '%"barrier"="bollard"%' ;
 UPDATE nodes_with_tags SET class='cattle grid' WHERE class IS NULL AND tags like '%"barrier"="cattle_grid"%' ;
 UPDATE nodes_with_tags SET class='gate' WHERE class IS NULL AND tags like '%"barrier"="gate"%' ;
 UPDATE nodes_with_tags SET class='turnstile' WHERE class IS NULL AND tags like '%"barrier"="kissing_gate"%' OR tags like '%"barrier"="turnstile"%' ;
 UPDATE nodes_with_tags SET class='lift gate' WHERE class IS NULL AND tags like '%"barrier"="lift_gate"%' ;
 UPDATE nodes_with_tags SET class='stile' WHERE class IS NULL AND tags like '%"barrier"="stile"%' ;
 UPDATE nodes_with_tags SET class='entrance' WHERE class IS NULL AND tags like '%"barrier"="entrance"%' ;
 UPDATE nodes_with_tags SET class='toll booth' WHERE class IS NULL AND tags like '%"barrier"="toll_booth"%' ;
 UPDATE nodes_with_tags SET class='barrier' WHERE class IS NULL AND tags like '%"barrier"%' ;
 UPDATE nodes_with_tags SET class='college' WHERE class IS NULL AND tags like '%"college%' ;
 UPDATE nodes_with_tags SET class='kindergarten, nursery' WHERE class IS NULL AND  tags like '%kindergarten%' or tags like '%nursery%' ;
 UPDATE nodes_with_tags SET class='school' WHERE class IS NULL AND tags like '%"amenity"="school"%' ;
 UPDATE nodes_with_tags SET class='university' WHERE class IS NULL AND tags like '%"university"%' ;
 UPDATE nodes_with_tags SET class='pub' WHERE class IS NULL AND  tags like '%"amenity"="pub"%' ;
 UPDATE nodes_with_tags SET class='dentist' WHERE class IS NULL AND tags like '%"dentist"%'  ;
 UPDATE nodes_with_tags SET class='doctor' WHERE class IS NULL AND tags like '%doctor%'  ;
 UPDATE nodes_with_tags SET class='optician' WHERE class IS NULL AND tags like '%"optician%' ;
 UPDATE nodes_with_tags SET class='veterinary' WHERE class IS NULL AND tags like '%"veterinary"%'  ;
 UPDATE nodes_with_tags SET class='tree cluster' WHERE class IS NULL AND tags like '%"natural"="tree"%' and tags like '%"cluster"%'  ;
 UPDATE nodes_with_tags SET class='broad leafed tree' WHERE class IS NULL AND tags like '%"natural"="tree"%' and tags like '%"broad_leafed"%'  ;
 UPDATE nodes_with_tags SET class='conifer' WHERE class IS NULL AND tags like '%"natural"="tree"%' and tags like '%"conifer"%'  ;
 UPDATE nodes_with_tags SET class='tree' WHERE class IS NULL AND tags like '%"natural"="tree"%' ;
 UPDATE nodes_with_tags SET class='bureau de change' WHERE class IS NULL AND tags like '%"bureau_de_change"%' ;
 UPDATE nodes_with_tags SET class='christian place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="christian"%' ;
 UPDATE nodes_with_tags SET class='jewish place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="jewish"%' ;
 UPDATE nodes_with_tags SET class='muslim place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="muslim"%' ;
 UPDATE nodes_with_tags SET class='bahai place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="bahai"%' ;
 UPDATE nodes_with_tags SET class='buddhist place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="buddhist"%' ;
 UPDATE nodes_with_tags SET class='hindu place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="hindu"%' ;
 UPDATE nodes_with_tags SET class='jain place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="jain"%' ;
 UPDATE nodes_with_tags SET class='shinto place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="shinto"%' ;
 UPDATE nodes_with_tags SET class='sikh place of worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' and tags like '%"religion"="sikh"%' ;
 UPDATE nodes_with_tags SET class='place_of_worship' WHERE class IS NULL AND tags like '%"place_of_worship"%' ;
 UPDATE nodes_with_tags SET class='battlefield' WHERE class IS NULL AND tags like '%"historic"="battlefield"%'  ;
 UPDATE nodes_with_tags SET class='art gallery' WHERE class IS NULL AND tags like '%"shop"="art"%'  or  tags like '%"gallery"%'  ;
 UPDATE nodes_with_tags SET class='beach' WHERE class IS NULL AND tags like '%"natural"="beach"%'  ;
 UPDATE nodes_with_tags SET class='casino' WHERE class IS NULL AND tags like '%"amenity"="casino"%' ;
 UPDATE nodes_with_tags SET class='cinema' WHERE class IS NULL AND tags like '%"amenity"="cinema"%' ;
 UPDATE nodes_with_tags SET class='clock' WHERE class IS NULL AND tags like '%"amenity"="clock"%' ;
 UPDATE nodes_with_tags SET class='memorial' WHERE class IS NULL AND tags like '%"historic"="memorial"%' ;
 UPDATE nodes_with_tags SET class='monument' WHERE class IS NULL AND tags like '%"historic"="monument"%' ;
 UPDATE nodes_with_tags SET class='steam railway' WHERE class IS NULL AND tags like '%steam%' and tags like '%"railway"%' ;
 UPDATE nodes_with_tags SET class='theme_park' WHERE class IS NULL AND tags like '%"tourism"="theme_park"%' ;
 UPDATE nodes_with_tags SET class='watermill' WHERE class IS NULL AND tags like '%"man_made"="watermill"%' ;
 UPDATE nodes_with_tags SET class='windmill' WHERE class IS NULL AND tags like '%"man_made"="windmill"%' ;
 UPDATE nodes_with_tags SET class='wreck' WHERE class IS NULL AND tags like '%"historic"="wreck"%' ;
 UPDATE nodes_with_tags SET class='zoo' WHERE class IS NULL AND tags like '%"tourism"="zoo"%' ;
 UPDATE nodes_with_tags SET class='cave_entrance' WHERE class IS NULL AND tags like '%"natural"="cave_entrance"%' ;
 UPDATE nodes_with_tags SET class='crane' WHERE class IS NULL AND tags like '%"man_made"="crane"%' ;
 UPDATE nodes_with_tags SET class='embassy' WHERE class IS NULL AND tags like '%"consulate"%' or tags like '%"embassy"%' ;
 UPDATE nodes_with_tags SET class='disused mining place' WHERE class IS NULL AND (tags like '%"mineshaft"%' OR tags like '%"landuse"="surface_mining"%' OR tags like '%"mine_entrance"%' OR tags like '%"landuse"="quarry"%') and ( tags like '%"disused"="yes"%' OR tags like '%"historic"%') ;
 UPDATE nodes_with_tags SET class='mining' WHERE class IS NULL AND (tags like '%"mineshaft"%' OR tags like '%"landuse"="surface_mining"%' OR tags like '%"mine_entrance"%' OR tags like '%"landuse"="quarry"%') and NOT (tags like '%"disused"="yes"%') ;
 UPDATE nodes_with_tags SET class='water tower' WHERE class IS NULL AND tags like '%"man_made"="water_tower"%' ;
 UPDATE nodes_with_tags SET class='beverage shop' WHERE class IS NULL AND tags like '%"shop"="alcohol"%' OR tags like '%"shop"="beverages"%' ;
 UPDATE nodes_with_tags SET class='bakery' WHERE class IS NULL AND tags like '%"shop"="bakery"%' ;
 UPDATE nodes_with_tags SET class='bicycle shop' WHERE class IS NULL AND tags like '%"shop"="bicycle"%' ;
 UPDATE nodes_with_tags SET class='bookshop' WHERE class IS NULL AND tags like '%"shop"="books"%' ;
 UPDATE nodes_with_tags SET class='butcher' WHERE class IS NULL AND tags like '%"shop"="butcher"%' ;
 UPDATE nodes_with_tags SET class='car shop' WHERE class IS NULL AND tags like '%"shop"="car"%' ;
 UPDATE nodes_with_tags SET class='car repair' WHERE class IS NULL AND tags like '%"shop"="car_repair"%' ;
 UPDATE nodes_with_tags SET class='clothes shop' WHERE class IS NULL AND tags like '%"shop"="clothes"%' ;
 UPDATE nodes_with_tags SET class='computer shop' WHERE class IS NULL AND tags like '%"shop"="computer"%' ;
 UPDATE nodes_with_tags SET class='confectionery shop' WHERE class IS NULL AND tags like '%"shop"="confectionery"%' ;
 UPDATE nodes_with_tags SET class='convenience shop' WHERE class IS NULL AND tags like '%"shop"="convenience"%' ;
 UPDATE nodes_with_tags SET class='copyshop' WHERE class IS NULL AND tags like '%"shop"="copyshop"%' ;
 UPDATE nodes_with_tags SET class='doityourself shop' WHERE class IS NULL AND tags like '%"shop"="doityourself"%' ;
 UPDATE nodes_with_tags SET class='estate agent' WHERE class IS NULL AND tags like '%"estate_agent"%' ;
 UPDATE nodes_with_tags SET class='seafood shop' WHERE class IS NULL AND tags like '%"shop"="seafood"%' ;
 UPDATE nodes_with_tags SET class='florist' WHERE class IS NULL AND tags like '%"shop"="florist"%' ;
 UPDATE nodes_with_tags SET class='garden centre' WHERE class IS NULL AND tags like '%"shop"="garden_centre"%' ;
 UPDATE nodes_with_tags SET class='gift shop' WHERE class IS NULL AND tags like '%"shop"="gift"%' ;
 UPDATE nodes_with_tags SET class='greengrocer' WHERE class IS NULL AND tags like '%"shop"="greengrocer"%' ;
 UPDATE nodes_with_tags SET class='hairdresser' WHERE class IS NULL AND tags like '%"shop"="hairdresser"%' ;
 UPDATE nodes_with_tags SET class='hifi shop' WHERE class IS NULL AND tags like '%"shop"="hifi"%' ;
 UPDATE nodes_with_tags SET class='jewelry' WHERE class IS NULL AND tags like '%"shop"="jewelry"%' ;
 UPDATE nodes_with_tags SET class='laundry' WHERE class IS NULL AND tags like '%"shop"="laundry"%' ;
 UPDATE nodes_with_tags SET class='mobile phone shop' WHERE class IS NULL AND tags like '%"shop"="mobile_phone"%' ;
 UPDATE nodes_with_tags SET class='motorcycle shop' WHERE class IS NULL AND tags like '%"shop"="motorcycle"%' ;
 UPDATE nodes_with_tags SET class='musical instrument shop' WHERE class IS NULL AND tags like '%"shop"="musical_instrument"%' ;
 UPDATE nodes_with_tags SET class='pet shop' WHERE class IS NULL AND tags like '%"shop"="pet"%' ;
 UPDATE nodes_with_tags SET class='camera shop' WHERE class IS NULL AND tags like '%"shop"="photo"%' OR tags like '%"shop"="camera%' ;
 UPDATE nodes_with_tags SET class='supermarket' WHERE class IS NULL AND tags like '%"shop"="supermarket"%' ;
 UPDATE nodes_with_tags SET class='fishing' WHERE class IS NULL AND tags like '%tackle%' or tags like '%"fishing"%' ;
 UPDATE nodes_with_tags SET class='video shop' WHERE class IS NULL AND tags like '%"shop"="video"%' ;
 UPDATE nodes_with_tags SET class='archery' WHERE class IS NULL AND tags like '%"sport"="archery"%' ;
 UPDATE nodes_with_tags SET class='baseball' WHERE class IS NULL AND tags like '%"sport"="baseball"%' ;
 UPDATE nodes_with_tags SET class='cricket' WHERE class IS NULL AND tags like '%"sport"="cricket"%' ;
 UPDATE nodes_with_tags SET class='diving' WHERE class IS NULL AND tags like '%"sport"="diving"%' ;
 UPDATE nodes_with_tags SET class='golf' WHERE class IS NULL AND tags like '%"sport"="golf"%' ;
 UPDATE nodes_with_tags SET class='gym' WHERE class IS NULL AND tags like '%"amenity"="gym"%' or  tags like '%"fitness%'  ;
 UPDATE nodes_with_tags SET class='gymnastics' WHERE class IS NULL AND tags like '%"sport"="gymnastics"%' ;
 UPDATE nodes_with_tags SET class='horse racing' WHERE class IS NULL AND tags like '%"sport"="horse_racing"%' ;
 UPDATE nodes_with_tags SET class='skating' WHERE class IS NULL AND tags like '%"sport"="skating"%' ;
 UPDATE nodes_with_tags SET class='motor sport' WHERE class IS NULL AND tags like '%"sport"="motor"%' ;
 UPDATE nodes_with_tags SET class='playground' WHERE class IS NULL AND tags like '%"leisure"="playground"%' ;
 UPDATE nodes_with_tags SET class='sailing' WHERE class IS NULL AND tags like '%"sailing%' ;
 UPDATE nodes_with_tags SET class='nordic ski piste' WHERE class IS NULL AND tags like '%"piste:type"="nordic"%' ;
 UPDATE nodes_with_tags SET class='downhill ski piste' WHERE class IS NULL AND tags like '%"piste:type"="downhill"%' ;
 UPDATE nodes_with_tags SET class='snooker' WHERE class IS NULL AND tags like '%snooker%'  ;
 UPDATE nodes_with_tags SET class='soccer' WHERE class IS NULL AND tags like '%"sport"="soccer"%' ;
 UPDATE nodes_with_tags SET class='swimming' WHERE class IS NULL AND tags like '%"swimming"%' ;
 UPDATE nodes_with_tags SET class='tennis' WHERE class IS NULL AND tags like '%"sport"="tennis"%' ;
 UPDATE nodes_with_tags SET class='windsurf' WHERE class IS NULL AND tags like '%windsurf%' ;
 UPDATE nodes_with_tags SET class='sport' WHERE class IS NULL AND tags like '%"leisure"%' or tags like '%"sport"%' ;
 UPDATE nodes_with_tags SET class='aerodrome' WHERE class IS NULL AND tags like '%"aeroway"="aerodrome"%' ;
 UPDATE nodes_with_tags SET class='airport' WHERE class IS NULL AND tags like '%"aeroway"="aerodrome"%' and tags like '%"iata"%' ;
 UPDATE nodes_with_tags SET class='fuel' WHERE class IS NULL AND tags like '%"amenity"="fuel"%' ;
 UPDATE nodes_with_tags SET class='parking (with places for disabled)' WHERE class IS NULL AND tags like '%"amenity"="parking"%' and (tags like '%"capacity:disabled"="yes"%'   ) ;
 UPDATE nodes_with_tags SET class='private parking' WHERE class IS NULL AND tags like '%"amenity"="parking"%' and ( tags like '%"access"="private"%' or tags like '%"access"="no"%') ;
 UPDATE nodes_with_tags SET class='parking' WHERE class IS NULL AND tags like '%"amenity"="parking"%' ;
 UPDATE nodes_with_tags SET class='airport gate' WHERE class IS NULL AND tags like '%"aeroway"="gate"%' ;
 UPDATE nodes_with_tags SET class='airport terminal' WHERE class IS NULL AND tags like '%"aeroway"="terminal"%' ;
 UPDATE nodes_with_tags SET class='car sharing' WHERE class IS NULL AND tags like '%"amenity"="car_sharing"%' ;
 UPDATE nodes_with_tags SET class='ford' WHERE class IS NULL AND tags like '%"highway"="ford"%' ;
 UPDATE nodes_with_tags SET class='lighthouse' WHERE class IS NULL AND tags like '%"man_made"="lighthouse"%' ;
 UPDATE nodes_with_tags SET class='marina' WHERE class IS NULL AND tags like '%"leisure"="marina"%' ;
 UPDATE nodes_with_tags SET class='bicycle parking' WHERE class IS NULL AND tags like '%"amenity"="bicycle_parking"%' ;
 UPDATE nodes_with_tags SET class='harbour' WHERE class IS NULL AND tags like '%"harbour"="yes"%' ;
 UPDATE nodes_with_tags SET class='bicycle rental' WHERE class IS NULL AND tags like '%"amenity"="bicycle_rental"%' ;
 UPDATE nodes_with_tags SET class='car rental' WHERE class IS NULL AND tags like '%"amenity"="car_rental"%' ;
 UPDATE nodes_with_tags SET class='roundabout' WHERE class IS NULL AND tags like '%roundabout"%' ;
 UPDATE nodes_with_tags SET class='roundabout' WHERE class IS NULL AND tags like '%roundabout"%' and tags like '%"direction"="clockwise"%' ;
 UPDATE nodes_with_tags SET class='traffic signals' WHERE class IS NULL AND tags like '%"highway"="traffic_signals"%' ;
 UPDATE nodes_with_tags SET class='railway halt' WHERE class IS NULL AND tags like '%"railway"="halt"%'  ;
 UPDATE nodes_with_tags SET class='railway station' WHERE class IS NULL AND tags like '%"railway"="station"%'  ;
 UPDATE nodes_with_tags SET class='subway entrance' WHERE class IS NULL AND tags like '%"railway"="subway_entrance"%' ;
 UPDATE nodes_with_tags SET class='tram stop' WHERE class IS NULL AND tags like '%"railway"="tram_stop"%' ;
 UPDATE nodes_with_tags SET class='turning circle' WHERE class IS NULL AND tags like '%"highway"="turning_circle"%' ;
 UPDATE nodes_with_tags SET class='weir' WHERE class IS NULL AND tags like '%"waterway"="weir"%' ;
 UPDATE nodes_with_tags SET class='aerialway station' WHERE class IS NULL AND tags like '%"aerialway"="station"%' ;
 UPDATE nodes_with_tags SET class='pylon' WHERE class IS NULL AND tags like '%"pylon"%' ;
 UPDATE nodes_with_tags SET class='crossing' WHERE class IS NULL AND tags like '%"highway"="crossing"%' OR tags like '%"railway"="crossing"%'  ;
 UPDATE nodes_with_tags SET class='railway crossing' WHERE class IS NULL AND tags like '%"railway"="crossing"%'  ;
 UPDATE nodes_with_tags SET class='level crossing' WHERE class IS NULL AND tags like '%"railway"="level_crossing"%' ;
 UPDATE nodes_with_tags SET class='motorway junction' WHERE class IS NULL AND tags like '%"highway"="motorway_junction"%' ;
 UPDATE nodes_with_tags SET class='noexit' WHERE class IS NULL AND tags like '%"noexit"="yes"%' ;
 UPDATE nodes_with_tags SET class='mountain pass' WHERE class IS NULL AND tags like '%"mountain_pass"="yes"%' ;
 UPDATE nodes_with_tags SET class='wayside shrine' WHERE class IS NULL AND tags like '%"historic"="wayside_shrine"%' ;
 UPDATE nodes_with_tags SET class='wayside cross' WHERE class IS NULL AND tags like '%"historic"="wayside_cross"%' ;
 UPDATE nodes_with_tags SET class='museum' WHERE class IS NULL AND tags like '%"tourism"="museum"%' ;
 UPDATE nodes_with_tags SET class='spring' WHERE class IS NULL AND tags like '%"natural"="spring"%' ;
 UPDATE nodes_with_tags SET class='tourist information' WHERE class IS NULL AND tags like '%"tourism"="information"%' ;
 UPDATE nodes_with_tags SET class='shop' WHERE class IS NULL AND tags like '%"shop"%' ;
 UPDATE nodes_with_tags SET class='tower' WHERE class IS NULL AND tags like '%"man_made"="tower"%' ;
 UPDATE nodes_with_tags SET class='waterfall' WHERE class IS NULL AND tags like '%"waterfall"%' ;
 UPDATE nodes_with_tags SET class='farmyard' WHERE class IS NULL AND tags like '%"landuse"="farmyard"%' or tags like '%"place"="farm"%' ;
 UPDATE nodes_with_tags SET class='city limit' WHERE class IS NULL AND tags like '%"traffic_sign"="city_limit"%' ;
 UPDATE nodes_with_tags SET class='stop' WHERE class IS NULL AND tags like '%"highway"="stop"%' ;
 UPDATE polygons SET class='pedestrian area' WHERE class IS NULL AND tags like '%"highway"="pedestrian"%' ;
 UPDATE polygons SET class='beach' WHERE class IS NULL AND tags like '%"natural"="beach"%' ;
 UPDATE polygons SET class='soccer' WHERE class IS NULL AND tags like '%"sport"="soccer"%' ;
 UPDATE polygons SET class='cemetery' WHERE class IS NULL AND tags like '%cemetery%' OR tags like '%grave_yard%' ;
 UPDATE polygons SET class='forest' WHERE class IS NULL AND tags like '%"forest"%'  OR tags like '%"wood"%' ;
 UPDATE polygons SET class='park, garden, playground' WHERE class IS NULL AND tags like '%"park"%' OR tags like '%"garden"%' OR tags like '%"playground"%' ;
 UPDATE polygons SET class='parking' WHERE class IS NULL AND tags like '%"parking"%' ;
 UPDATE polygons SET class='with fee' WHERE class IS NULL AND tags like '%"fee"="yes"%' ;
 UPDATE polygons SET class='leisure area' WHERE class IS NULL AND tags like '%"leisure"%' and not (tags like '%"leisure"="golf_course"%') ;
 UPDATE polygons SET class='coastline' WHERE class IS NULL AND tags like '%"coastline"%' ;
 UPDATE polygons SET class='highway; area accessible to vehicles' WHERE class IS NULL AND tags like '%highway%' ;
 UPDATE polygons SET class='residential' WHERE class IS NULL AND tags like '%"landuse"="residential"%' ;
 UPDATE polygons SET class='building' WHERE class IS NULL AND tags like '%"building"%' ;
 UPDATE polygons SET class='lake, large river' WHERE class IS NULL AND tags like '%"natural"="water"%' OR tags like '%"waterway"="riverbank"%' ;
 UPDATE polygons SET class='camp site' WHERE class IS NULL AND tags like '%"tourism"="camp_site"%' ;
 UPDATE polygons SET class='farmyard' WHERE class IS NULL AND tags like '%"landuse"="farmyard"%' ;
 UPDATE polygons SET class='farm land' WHERE class IS NULL AND tags like '%"landuse"="farm"%' OR tags like '%"landuse"="farmland"%' ;
 UPDATE polygons SET class='grass' WHERE class IS NULL AND tags like '%"landuse"="grass"%' ;
 UPDATE polygons SET class='meadow' WHERE class IS NULL AND tags like '%"landuse"="meadow"%' ;
 UPDATE polygons SET class='scrub, heath' WHERE class IS NULL AND tags like '%"natural"="scrub"%' or tags like '%"natural"="heath"%' ;
 UPDATE polygons SET class='industrial' WHERE class IS NULL AND tags like '%"landuse"="industrial"%' ;
 UPDATE polygons SET class='golf course' WHERE class IS NULL AND tags like '%"leisure"="golf_course"%' ;
 UPDATE polygons SET class='quarry' WHERE class IS NULL AND tags like '%"landuse"="quarry"%' ;
 UPDATE polygons SET class='power facility' WHERE class IS NULL AND tags like '%"power"%' ;
 UPDATE polygons SET class='wastewater plant' WHERE class IS NULL AND tags like '%"wastewater_plant"%' ;
 UPDATE polygons SET class='hospital' WHERE class IS NULL AND tags like '%"amenity"="hospital"%' ;





_EOF_

# Rivers, streams... are represented in ways that touch themself in the middle of lakes and
# large rivers. This generates ugly labelling of those ways.
# The following cuts their parts that are in lakes or over larger rivers, when appropriate
if [ "$rivers" = "cut" ]; then

${psql_folder}psql $pgconnect_user  -d $dbname  <<- _EOF_

UPDATE ways SET linestring=newriver FROM (SELECT  * FROM (SELECT ways.id, ST_Difference(linestring,
(SELECT ST_Union(polygons.polygon) FROM polygons
WHERE ST_Intersects(polygons.polygon, ways.linestring)
and (polygons.tagshstore ? 'waterway' OR polygons.tagshstore @> 'natural=>water' )
-- large rivers are represented both as polygons and ways: polygons are used at large scales and
-- ways at small scales, so keep both when polygons.name != ways.name 
and (polygons.name != ways.name OR polygons.name IS NULL)
)  ) as newriver FROM ways
WHERE (ways.tagshstore @> 'waterway=>stream' OR
ways.tagshstore @> 'waterway=>river' OR
ways.tagshstore @> 'waterway=>riverbank' OR
ways.tagshstore @> 'waterway=>canal' OR
ways.tagshstore @> 'waterway=>derelict_canal' OR
ways.tagshstore @> 'waterway=>ditch' OR
ways.tagshstore @> 'waterway=>drain' OR
-- do not modify weirs, dams, etc. that are not piece of water but are stopping water
ways.tagshstore @> 'natural=>water'   )
-- a canal can be on a bridge or on a tunnel (?) in this case it should be displayed
AND NOT (ways.tagshstore ? 'bridge' OR ways.tagshstore ? 'tunnel' OR ways.tagshstore @> 'lock=>yes')
) as newrivers
WHERE
--  cleaning is necessary (or it fails)
-- E.g. the two following objects (one line and one polygon) represent exactly the same object
-- (the first is included in the second, the result is a [valid?!] geometry with zero points)
-- http://www.openstreetmap.org/browse/way/64796488  and http://www.openstreetmap.org/browse/way/64796484
ST_IsValid(newriver)
AND GeometryType(newriver) = 'LINESTRING'
AND ST_NPoints(newriver) >1) as newrivers2
WHERE ways.id=newrivers2.id ;

_EOF_
fi
echo "Time: Finished importation at `date +"%Y-%m-%d_%H:%M:%S"`"
echo -e "Importation completed correctly!
$how_to_remove
"

exit
