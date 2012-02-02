SELECT SUM(cost) FROM shortest_path('SELECT gid AS id, source, target, length AS cost FROM network', :startid, :endid,false,false);
		
		
