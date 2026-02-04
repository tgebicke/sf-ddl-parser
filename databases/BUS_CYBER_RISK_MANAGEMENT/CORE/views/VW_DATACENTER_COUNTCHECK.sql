create or replace view VW_DATACENTER_COUNTCHECK(
	REPORT_ID,
	DATACENTER_ID,
	ACRONYM,
	COMMONNAME,
	MIN_SYSTEMS,
	MAX_SYSTEMS,
	AVG_SYSTEMS,
	MIN_VULASSETS,
	MAX_VULASSETS,
	AVG_VULASSETS,
	MIN_VULCRITICAL,
	MAX_VULCRITICAL,
	AVG_VULCRITICAL,
	MIN_VULHIGH,
	MAX_VULHIGH,
	AVG_VULHIGH,
	MIN_VULRAW,
	MAX_VULRAW,
	AVG_VULRAW,
	MIN_VULRAW_CRITICAL,
	MAX_VULRAW_CRITICAL,
	AVG_VULRAW_CRITICAL,
	MIN_VULRAW_HIGH,
	MAX_VULRAW_HIGH,
	AVG_VULRAW_HIGH,
	MIN_HWAMRAWAWS,
	MAX_HWAMRAWAWS,
	AVG_HWAMRAWAWS,
	MIN_HWAMRAWBIGFIX,
	MAX_HWAMRAWBIGFIX,
	AVG_HWAMRAWBIGFIX,
	MIN_HWAMRAWFORESCOUT,
	MAX_HWAMRAWFORESCOUT,
	AVG_HWAMRAWFORESCOUT
) COMMENT='Returns history of datacenter min/max/avg metrics about  hwam,vuln, asset and system.'
 as
SELECT 
dcs.REPORT_ID
,dcs.DATACENTER_ID
,dc.Acronym
,dc.CommonName
-- Systems
,Min(dcs.Systems) as Min_Systems
,Max(dcs.Systems) as Max_Systems
,Avg(dcs.Systems) as Avg_Systems
-- Assets
,Min(dcs.Assets) as Min_VulAssets
,Max(dcs.Assets) as Max_VulAssets
,Avg(dcs.Assets) as Avg_VulAssets
-- VUL
,Min(dcs.VulCritical) as Min_VulCritical
,Max(dcs.VulCritical) as Max_VulCritical
,Avg(dcs.VulCritical) as Avg_VulCritical
,Min(dcs.VulHigh) as Min_VulHigh
,Max(dcs.VulHigh) as Max_VulHigh
,Avg(dcs.VulHigh) as Avg_VulHigh
,Min(dcs.VulRaw) as Min_VulRaw
,Max(dcs.VulRaw) as Max_VulRaw
,Avg(dcs.VulRaw) as Avg_VulRaw
,Min(dcs.VulRaw_Critical) as Min_VulRaw_Critical
,Max(dcs.VulRaw_Critical) as Max_VulRaw_Critical
,Avg(dcs.VulRaw_Critical) as Avg_VulRaw_Critical
,Min(dcs.VulRaw_High) as Min_VulRaw_High
,Max(dcs.VulRaw_High) as Max_VulRaw_High
,Avg(dcs.VulRaw_High) as Avg_VulRaw_High
-- HWAM
,Min(dcs.HWAMRawAWS) as Min_HWAMRawAWS
,Max(dcs.HWAMRawAWS) as Max_HWAMRawAWS
,Avg(dcs.HWAMRawAWS) as Avg_HWAMRawAWS
,Min(dcs.HWAMRawBigFix) as Min_HWAMRawBigFix
,Max(dcs.HWAMRawBigFix) as Max_HWAMRawBigFix
,Avg(dcs.HWAMRawBigFix) as Avg_HWAMRawBigFix
,Min(dcs.HWAMRawForeScout) as Min_HWAMRawForeScout
,Max(dcs.HWAMRawForeScout) as Max_HWAMRawForeScout
,Avg(dcs.HWAMRawForeScout) as Avg_HWAMRawForeScout
FROM CORE.DataCenterSummary dcs
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = dcs.DATACENTER_ID
JOIN CORE.VW_REPORTSNAPSHOTS r on r.REPORT_ID = dcs.REPORT_ID
GROUP BY dcs.REPORT_ID
,dcs.DATACENTER_ID
,dc.SYSTEM_ID
,dc.Acronym
,dc.CommonName
ORDER BY dcs.REPORT_ID desc
,dc.Acronym
,dc.CommonName;