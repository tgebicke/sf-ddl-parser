create or replace view VW_LIST_CRM_VIEWS(
	THEOBJECT
) COMMENT='View can be used to list production views for testing their functionality\t'
 as
--
-- SELECT 'SELECT TOP 1 ' || char(39) || DBSCHEMA || char(46)  || OBJECTNAME || char(39) || ' FROM ' || DBSCHEMA || '.' || char(34) || OBJECTNAME || char(34) || ' UNION ALL' as TheObject
-- FROM DBA.VW_LIST_CRM_OBJECTS WHERE OBJECTTYPE = 'View' AND DBSCHEMA IN ('CEDE','CORE','DBA','RPT')
--
SELECT 'SELECT * FROM ' || DBSCHEMA || '.' || char(34) || OBJECTNAME || char(34) || ' limit 2;' as TheObject
FROM DBA.VW_LIST_CRM_OBJECTS WHERE OBJECTTYPE = 'View' AND DBSCHEMA IN ('CEDE','CORE','DBA','RPT')
ORDER BY DBSCHEMA, OBJECTNAME;