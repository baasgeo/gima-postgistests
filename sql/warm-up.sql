-- create network topology from OSM data
-- clean up existing tables

CREATE OR REPLACE FUNCTION warmup() RETURNS void AS $$
  DECLARE
	rec RECORD;
BEGIN -- start the transaction
    FOR rec IN SELECT * FROM geometry_columns LOOP
        RAISE NOTICE 'table %', rec.f_table_name;
        EXECUTE 'SELECT * FROM ' || quote_ident(rec.f_table_name);
    END LOOP;
END;
$$ LANGUAGE 'plpgsql';

SELECT warmup();