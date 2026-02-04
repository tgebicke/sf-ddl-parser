create or replace view VW_DATACENTERSUMMARY(
	REPORT_ID,
	DATACENTER_ID,
	REPORTDATE,
	ACRONYM,
	COMMONNAME,
	OPERATIONALSYSTEMS,
	SYSTEMS,
	ASSETS,
	VULCRITICAL,
	VULCRITICAL_LTE15DAYS,
	VULUNIQUECRITICAL_GT15_LTE60DAYS,
	VULCRITICAL_LTE30DAYS,
	VULUNIQUECRITICAL_GT30_LTE60DAYS,
	VULCRITICAL_GT30_LTE60DAYS,
	VULUNIQUECRITICAL_GT60DAYS,
	VULCRITICAL_GT60DAYS,
	VULHIGH,
	VULHIGH_LTE30DAYS,
	VULUNIQUEHIGH_GT30_LTE60DAYS,
	VULHIGH_GT30_LTE60DAYS,
	VULUNIQUEHIGH_GT60DAYS,
	VULHIGH_GT60DAYS,
	VULRAW,
	VULRAW_CRITICAL,
	VULRAW_HIGH,
	VULRAW_LOW,
	VULRAW_MEDIUM,
	HWAMRAWAWS,
	HWAMRAWBIGFIX,
	HWAMRAWFORESCOUT
) COMMENT='Returns history of datacenter summary.'
 as
SELECT
dcs.REPORT_ID
,dcs.DATACENTER_ID
,cast(r.REPORT_DATE as date) as ReportDate
,dc.Acronym
,dc.CommonName
,dcs.OperationalSystems
,dcs.Systems
--,dcs.AdjSystems
,dcs.Assets
--,dcs.AdjAssets
,dcs.VulCritical
,dcs.VulCritical_lte15days
,dcs.VulUniqueCritical_gt15_lte60days
,dcs.VulCritical_lte30days
,dcs.VulUniqueCritical_gt30_lte60days
,dcs.VulCritical_gt30_lte60days
,dcs.VulUniqueCritical_gt60days
,dcs.VulCritical_gt60days
,dcs.VulHigh
,dcs.VulHigh_lte30days
,dcs.VulUniqueHigh_gt30_lte60days
,dcs.VulHigh_gt30_lte60days
,dcs.VulUniqueHigh_gt60days
,dcs.VulHigh_gt60days
,dcs.VulRaw
,dcs.VulRaw_Critical
,dcs.VulRaw_High
,dcs.VulRaw_Low
,dcs.VulRaw_Medium
-- HWAM
,dcs.HWAMRawAWS
,dcs.HWAMRawBigFix
,dcs.HWAMRawForeScout
FROM CORE.DataCenterSummary dcs
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = dcs.DATACENTER_ID
JOIN CORE.REPORT_IDS r on r.REPORT_ID = dcs.REPORT_ID
ORDER BY r.REPORT_DATE desc
,dc.Acronym;