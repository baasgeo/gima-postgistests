select n.name, p.edge_id, o.highway from network n, (select edge_id from 
shortest_path('SELECT gid as id, source, target, length as cost FROM network',
(select source from network where name='Westrandweg' limit 1),
(select source from network where name='Overslag' limit 1),false,false)) p, planet_osm_line o
where p.edge_id = n.gid and n.osm_id = o.osm_id;

SELECT SUM(cost) FROM shortest_path('SELECT gid as id, source, target, length as cost FROM network', 5, 40318,false,false);