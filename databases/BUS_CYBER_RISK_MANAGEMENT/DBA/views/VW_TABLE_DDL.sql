create or replace view VW_TABLE_DDL(
	STMT
) COMMENT='View generates list of GET_DDL statements for each CORE table. Subsequent select statements must be executed\t'
 as
SELECT 'SELECT GET_DDL(''TABLE'',''' || table_schema || '.' || table_name || ''') as STMT UNION ALL' AS stmt
FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = 'CORE' AND TABLE_TYPE = 'BASE TABLE' order by table_name;