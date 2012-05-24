-- bouding box query for all OSM geometry columns      
--CREATE TABLE IF NOT EXISTS boundarybox (id SERIAL PRIMARY KEY, name VARCHAR(64), the_geog GEOGRAPHY(POLYGON,4326), the_geom GEOMETRY(POLYGON,4326));
--CREATE UNIQUE INDEX boundarybox_gix ON boundarybox USING GIST ( the_geog );

CREATE TABLE IF NOT EXISTS boundarybox (
  id SERIAL PRIMARY KEY,
  name VARCHAR(64)
);
SELECT AddGeometryColumn('boundarybox', 'the_geom', 4326, 'GEOMETRY', 2 );

INSERT INTO boundarybox (name, the_geom)
	VALUES (:bboxname, ST_MakeEnvelope(:bbox));