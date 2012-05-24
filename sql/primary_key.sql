-- add a serial column and define that as the primary key
ALTER TABLE planet_osm_point ADD COLUMN pid serial;
ALTER TABLE planet_osm_point ADD CONSTRAINT pid_pkey_point PRIMARY KEY (pid);
ALTER TABLE planet_osm_line ADD COLUMN pid serial;
ALTER TABLE planet_osm_line ADD CONSTRAINT pid_pkey_line PRIMARY KEY (pid); 
ALTER TABLE planet_osm_polygon ADD COLUMN pid serial;
ALTER TABLE planet_osm_polygon ADD CONSTRAINT pid_pkey_polygon PRIMARY KEY (pid);