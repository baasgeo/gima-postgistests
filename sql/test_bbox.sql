-- bouding box query
select count(way) from (select * from planet_osm_line where ST_Within(way, ST_MakeEnvelope(:bbox))) as result; 

