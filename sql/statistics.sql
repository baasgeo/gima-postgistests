-- determining database statistics
-- database size
SELECT pg_size_pretty(pg_database_size(:database)) As fulldbsize;

-- geometry statistics
SELECT (
        SELECT COUNT(*)
        from planet_osm_point
        ) AS points,
        (
        SELECT COUNT(*)
        from planet_osm_line
        ) AS lines,
        (
        SELECT COUNT(*)
        from planet_osm_polygon
        ) AS polygons;