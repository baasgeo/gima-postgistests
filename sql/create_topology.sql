-- create network topology from OSM data
-- clean up existing tables
DROP TABLE IF EXISTS network CASCADE;
DROP TABLE IF EXISTS vertices_tmp CASCADE;
CREATE TABLE network(gid serial, osm_id INTEGER, name VARCHAR, the_geom GEOMETRY, source INTEGER, target INTEGER, length FLOAT);

CREATE OR REPLACE FUNCTION create_network() RETURNS text AS $$
DECLARE
streetRecord record;
wayRecord record;
pointCount integer;
pointIndex integer;
geomFragment record;
BEGIN -- start the transaction
FOR streetRecord IN SELECT way, osm_id, name FROM planet_osm_line 
    WHERE highway IS NOT NULL AND highway NOT IN ('cycleway','footway','pedestrain','service') LOOP
 SELECT * FROM planet_osm_ways WHERE id = streetRecord.osm_id INTO wayRecord; 
 FOR pointIndex IN array_lower(wayRecord.nodes, 1)..array_upper(wayRecord.nodes,1)-1 LOOP
  SELECT st_makeline(st_pointn(streetRecord.way, pointIndex), st_pointn(streetRecord.way, pointIndex+1)) AS way 
    INTO geomFragment;
  INSERT INTO network(osm_id, name, the_geom, source, target, length) 
    VALUES(streetRecord.osm_id, 
        streetRecord.name, 
        geomFragment.way, 
        wayRecord.nodes[pointIndex], 
        wayRecord.nodes[pointIndex+1], 
        st_length(ST_GeogFromWKB(geomFragment.way), 
        false));
 END LOOP;
END LOOP;
return 'Done';
END;
$$ LANGUAGE 'plpgsql';

SELECT create_network();
-- clean up null values
DELETE FROM network WHERE LENGTH IS NULL;
-- fill in topology table's geometry column
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
    SELECT '', 'public', 'network', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
	FROM network LIMIT 1;
SELECT assign_vertex_id('network', 0.00002, 'the_geom', 'gid');