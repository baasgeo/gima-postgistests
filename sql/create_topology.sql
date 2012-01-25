drop table if exists network cascade;
create table network(gid serial, osm_id integer, name varchar, the_geom geometry, source integer, target integer, length float);

CREATE OR REPLACE FUNCTION compute_network() RETURNS text as $$
DECLARE
streetRecord record;
wayRecord record;
pointCount integer;
pointIndex integer;
geomFragment record;
BEGIN
-- for each street
FOR streetRecord in select way, osm_id, name from planet_osm_line where highway is not null and highway not in ('cycleway','footway','pedestrain','service') LOOP
 SELECT * from planet_osm_ways where id = streetRecord.osm_id into wayRecord; 
 FOR pointIndex in array_lower(wayRecord.nodes, 1)..array_upper(wayRecord.nodes,1)-1 LOOP
  RAISE NOTICE 'Inserting name % source %, target %', streetRecord.name, wayRecord.nodes[pointIndex], wayRecord.nodes[pointIndex+1];
  select st_makeline(st_pointn(streetRecord.way, pointIndex), st_pointn(streetRecord.way, pointIndex+1)) as way into geomFragment;
  insert into network(osm_id, name, the_geom, source, target, length) values(streetRecord.osm_id, streetRecord.name, geomFragment.way, wayRecord.nodes[pointIndex], wayRecord.nodes[pointIndex+1], st_length(ST_GeogFromWKB(geomFragment.way)));
 END LOOP;
END LOOP;
return 'Done';
END;
$$ LANGUAGE 'plpgsql';

select * from compute_network();
-- clean up null values
delete from network where length is null;
-- fill in topology table's geometry column
insert into geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
    select '', 'public', 'network', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
	from network limit 1;
select assign_vertex_id('network', 0.002, 'the_geom', 'gid');