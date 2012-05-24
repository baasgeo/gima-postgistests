-- bouding box GML query for all OSM geometry columns     
\pset pager
SELECT ST_AsGML(way,3) FROM planet_osm_point WHERE ST_Within(way, ST_MakeEnvelope(:bbox))
UNION ALL
SELECT ST_AsGML(way,3) FROM planet_osm_line WHERE ST_Within(way, ST_MakeEnvelope(:bbox))
UNION ALL
SELECT ST_AsGML(way,3) FROM planet_osm_polygon WHERE ST_Within(way, ST_MakeEnvelope(:bbox));