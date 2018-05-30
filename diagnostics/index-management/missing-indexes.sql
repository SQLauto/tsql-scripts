-----------------------------------------------------------------
-- find missing indexes in the current database
--
-- rudi@babaluga.com, go ahead license
-----------------------------------------------------------------

SELECT	
	object_name(object_id) as [table], 
	d.equality_columns + COALESCE(', ' + d.inequality_columns, '') as key_columns,
	d.included_columns,
	s.avg_total_user_cost,
	s.avg_user_impact,
	s.user_seeks + s.user_scans as usage,
	COALESCE(s.last_user_seek, s.last_user_scan) as last_usage
FROM	sys.dm_db_missing_index_details d 
INNER JOIN sys.dm_db_missing_index_groups g
	ON	d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s
	ON	g.index_group_handle = s.group_handle
WHERE	database_id = db_id()
ORDER BY  s.user_seeks DESC, object_id;

-------------------------------
--   to create the indexes   --
-------------------------------
SELECT	
	'CREATE INDEX nix$' + lower(object_name(object_id)) + '$' 
	+ REPLACE(REPLACE(REPLACE(COALESCE(equality_columns, inequality_columns), ']', ''), '[', ''), ', ', '_')
	+ ' ON ' + statement + ' (' + COALESCE(equality_columns, inequality_columns) 
	+ COALESCE(') INCLUDE (' + included_columns, '') + ')'
FROM	sys.dm_db_missing_index_details d 
INNER JOIN sys.dm_db_missing_index_groups g
	ON	d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s
	ON	g.index_group_handle = s.group_handle
WHERE	database_id = db_id()
ORDER BY  s.user_seeks DESC;