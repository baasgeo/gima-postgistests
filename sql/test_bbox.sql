-- bouding box query for all OSM geometry columns      
SELECT *, lines+points+polygons AS total FROM
	(SELECT (
		SELECT COUNT(*)
        FROM planet_osm_point WHERE ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS points,
        (
        SELECT COUNT(*)
        FROM planet_osm_line WHERE ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS lines,
        (
        SELECT COUNT(*)
        FROM planet_osm_polygon WHERE ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS polygons
    ) AS bbox;