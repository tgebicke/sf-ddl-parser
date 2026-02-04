create or replace view VW_CRMP_PCTHIGHCLOSEDLEGACY(
	SYSTEMNAME,
	OPENEDLEGACY,
	CLOSEDLEGACY,
	PERCENTAGECLOSED
) COMMENT='Shows total high legacy vulnerability combine all systems open,closed and percentage closed,  used for CRMP.'
 as
Select 
LevelName AS SystemName
,NotClosedTimely AS OpenedLegacy
,TotalClosed AS ClosedLegacy
,PercentageClosed
from TABLE(CORE.FN_CRM_METRICS('System','High',TRUE))
;