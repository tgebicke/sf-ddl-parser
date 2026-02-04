create or replace view VW_CRMP_PCTHIGHCLOSEDWITHIN60DAYS(
	SYSTEMNAME,
	OPENORCLOSEBEYOND60DAYS,
	CLOSEDBY60DAYS,
	PERCENTAGECLOSED
) COMMENT='Shows percentage high vulnerability combine all systems  closed within 60 days, used for CRMP.'
 as
Select 
LevelName AS SystemName
,NotClosedTimely AS OpenOrCloseBeyond60Days
,TotalClosed AS ClosedBy60Days
,PercentageClosed
from TABLE(CORE.FN_CRM_METRICS('System','High',FALSE))
;