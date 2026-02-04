create or replace view VW_ROWCOUNT_FOR_VIEWS(
	THECOMMAND
) COMMENT='View is used to obtain row counts for all the views found in the production schemas\t'
 as
SELECT 
'SELECT ' || char(39) || OBJECTNAME || char(39) || ' as ObjectName, count(1) as TotalRows'  || ' FROM ' || DBSCHEMA || '.' || char(34) || OBJECTNAME || char(34) || ' UNION ALL' as TheCommand
FROM DBA.VW_LIST_CRM_OBJECTS WHERE OBJECTTYPE = 'View' AND DBSCHEMA IN ('CEDE','CORE','DBA','RPT')
ORDER BY DBSCHEMA, OBJECTNAME;