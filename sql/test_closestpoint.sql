SELECT id, ST_Distance_Spheroid(pt, ST_ClosestPoint(geom,pt), 'SPHEROID["WGS 84",6378137,298.257223563]') as dist
FROM (
	--SELECT ST_GeomFromEWKT(:point)::geometry AS pt, way AS geom, osm_id AS id FROM planet_osm_line
	--UNION
	SELECT ST_GeomFromEWKT(:point)::geometry AS pt, way AS geom, osm_id AS id FROM planet_osm_point
	) AS points ORDER BY dist LIMIT 1;