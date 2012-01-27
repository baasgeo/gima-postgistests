SELECT id, ST_Distance(ST_ClosestPoint(pt,geom), ST_ClosestPoint(geom,pt)) as dist
FROM (
	SELECT ST_GeomFromEWKT(:point)::geometry AS pt, way AS geom, osm_id AS id FROM planet_osm_line
	UNION
	SELECT ST_GeomFromEWKT(:point)::geometry AS pt, way AS geom, osm_id AS id FROM planet_osm_point
	) AS distance ORDER BY dist LIMIT 1;