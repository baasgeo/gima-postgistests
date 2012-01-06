-- shortest path based on node id
select * from planet_osm_line where ST_Within(way, ST_MakeEnvelope(4.88557, 52.36694, 4.91214, 52.37674, 4326)); 
select extent(way) from planet_osm_line; 

