SELECT SUM(cost) FROM shortest_path('SELECT gid as id, source, target, length as cost FROM network', 15685, 7231,false,false);
		
		
