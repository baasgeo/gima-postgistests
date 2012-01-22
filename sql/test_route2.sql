SELECT SUM(cost) FROM shortest_path('SELECT gid as id, source, target, length as cost FROM network', :startid, :endid,false,false);
		
		
