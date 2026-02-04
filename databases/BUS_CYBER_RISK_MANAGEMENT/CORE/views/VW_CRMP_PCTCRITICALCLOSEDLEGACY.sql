create or replace view VW_CRMP_PCTCRITICALCLOSEDLEGACY(
	SYSTEMNAME,
	OPENEDLEGACY,
	CLOSEDLEGACY,
	PERCENTAGECLOSED
) COMMENT='Shows total critical legacy vulnerability combine all systems open,closed and percentage closed  used for CRMP.'
 as
Select 
LevelName AS SystemName
,NotClosedTimely AS OpenedLegacy
,TotalClosed AS ClosedLegacy
,PercentageClosed
from TABLE(CORE.FN_CRM_METRICS('System','Critical',TRUE));