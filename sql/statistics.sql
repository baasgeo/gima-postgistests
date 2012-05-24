-- determining database statistics
\pset pager
\d+
\d+ planet_osm_point
\d+ planet_osm_line
\d+ planet_osm_polygon
\d+ network
\d+ vertices_tmp

-- osm statistics
SELECT (
        SELECT COUNT(*)
        FROM planet_osm_nodes
        ) AS nodes,
        (
        SELECT COUNT(*)
        FROM planet_osm_ways
        ) AS ways,
        (
        SELECT COUNT(*)
        FROM planet_osm_rels
        ) AS relations;

-- geometry statistics
SELECT (
        SELECT COUNT(*)
        FROM planet_osm_point
        ) AS points,
        (
        SELECT COUNT(*)
        FROM planet_osm_line
        ) AS lines,
        (
        SELECT COUNT(*)
        FROM planet_osm_polygon
        ) AS polygons;

-- database size
SELECT pg_size_pretty(pg_database_size(:database)) As fulldbsize;