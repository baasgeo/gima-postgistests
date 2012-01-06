SQL: select * from (SELECT network.*, route.cost AS route_cost FROM network JOIN (SELECT * FROM shortest_path('SELECT gid AS id, source::int4 AS source, target::int4 AS target, length::float8 AS cost  FROM network ', 191266,190866, False, False)) AS route ON network.gid= route.edge_id) as "subQuery_0" limit 1



select n.name, p.edge_id, o.highway from network n, (select edge_id from 
shortest_path('SELECT gid as id, source, target, length as cost FROM network',
(select source from network where name='Westrandweg' limit 1),
(select source from network where name='Overslag' limit 1),false,false)) p, planet_osm_line o
where p.edge_id = n.gid and n.osm_id = o.osm_id;

SELECT COUNT(cost) FROM shortest_path('SELECT gid as id, source, target, length as cost FROM network', 5, 40318,false,false);