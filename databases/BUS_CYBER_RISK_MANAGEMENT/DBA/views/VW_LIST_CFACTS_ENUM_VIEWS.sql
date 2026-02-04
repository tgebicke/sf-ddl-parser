create or replace view VW_LIST_CFACTS_ENUM_VIEWS(
	THECOMMAND
) COMMENT='Get list of APP_CFACTS SEC_VW_ENUM views for obtaining Values\t'
 as
SELECT 'SELECT ' || char(39) || TABLE_NAME || char(39) || ' as TheTable, ID, VALUE FROM ' 
|| TABLE_CATALOG || '.' || TABLE_SCHEMA || '.' || TABLE_NAME || ' UNION ALL' as TheCommand
FROM APP_CFACTS.INFORMATION_SCHEMA.VIEWS v
WHERE v.TABLE_SCHEMA IN ('SHARED') and UPPER(TABLE_NAME) LIKE '%ENUM%'
order by TABLE_NAME
;