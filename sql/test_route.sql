-- shortest path based on node id
SELECT SUM(cost) FROM shortest_path('SELECT gid as id, source, target, length as cost FROM network', 5, 40318,false,false);