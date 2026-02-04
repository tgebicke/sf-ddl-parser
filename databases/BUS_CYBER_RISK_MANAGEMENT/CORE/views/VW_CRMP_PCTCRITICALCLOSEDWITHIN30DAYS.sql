create or replace view VW_CRMP_PCTCRITICALCLOSEDWITHIN30DAYS(
	SYSTEMNAME,
	OPENORCLOSEBEYOND30DAYS,
	CLOSEDBY30DAYS,
	PERCENTAGECLOSED
) COMMENT='Shows percentage critical vulnerability combine all systems  closed within 30 days, used for CRMP.'
 as
Select 
LevelName AS SystemName
,NotClosedTimely AS OpenOrCloseBeyond30Days
,TotalClosed AS ClosedBy30Days
,PercentageClosed
from TABLE(CORE.FN_CRM_METRICS('System','Critical',FALSE))
--from TABLE(CORE.FN_CRM_METRICS('System','High',FALSE))
;