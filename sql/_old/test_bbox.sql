-- bouding box query for all OSM geometry columns
SELECT (
        SELECT COUNT(*)
        from planet_osm_line where ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS lines,
        (
        SELECT COUNT(*)
        from planet_osm_point where ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS points,
        (
        SELECT COUNT(*)
        from planet_osm_polygon where ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS polygons;
        
Select *, lines+points+polygons as total from 
	(SELECT (
        SELECT COUNT(*)
        from planet_osm_line where ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS lines,
        (
        SELECT COUNT(*)
        from planet_osm_point where ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS points,
        (
        SELECT COUNT(*)
        from planet_osm_polygon where ST_Within(way, ST_MakeEnvelope(:bbox))
        ) AS polygons
    ) as bbox;