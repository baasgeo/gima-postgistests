ALTER TABLE planet_osm_line ADD COLUMN the_geog geography;
UPDATE planet_osm_line SET the_geog = ST_GeogFromWKB(way);

ALTER TABLE planet_osm_point ADD COLUMN the_geog geography;
UPDATE planet_osm_point SET the_geog = ST_GeogFromWKB(way);

ALTER TABLE planet_osm_polygon ADD COLUMN the_geog geography;
UPDATE planet_osm_polygon SET the_geog = ST_GeogFromWKB(way);

ALTER TABLE planet_osm_roads ADD COLUMN the_geog geography;
UPDATE planet_osm_roads SET the_geog = ST_GeogFromWKB(way);