create or replace view V_CYBERRISK_MONTH_TREND(
	"ReportDate",
	"Is_endOfMonth",
	"OperationalSystems",
	"TotalSystems",
	"TotalAdjSystems",
	"Assets",
	"AdjAssets",
	"TotalCritical+High",
	"Critical Vulnerabilities",
	"Critical: <= 15 days",
	"Unique Critical: > 15 <= 60 days",
	"Critical: <= 30 days",
	"Unique Critical: > 30 <= 60 days",
	"Critical: > 30 <= 60 days",
	"Unique Critical: > 60 days",
	"Critical: > 60 days",
	"High Vulnerabilities",
	"High: <= 30 days",
	"Unique High: > 30 <= 60 days",
	"High: > 30 <= 60 days",
	"Unique High: > 60 days",
	"High: > 60 days",
	"VulCritical_gte15days",
	"VulRaw",
	"VulRaw_Critical",
	"VulRaw_High",
	"VulRaw_Low",
	"VulRaw_Medium",
	"VulUniqueCritical_gte15days",
	"HWAMRawAWS",
	"HWAMRawBigFix",
	"HWAMRawForeScout"
) COMMENT='Used in other views to get trending data for Vuln data category'
 as
select 
cast(r.REPORT_DATE as date) as "ReportDate"
,r.Is_endOfMonth as "Is_endOfMonth"
,dcs."OperationalSystems"
,dcs."TotalSystems"
,dcs."TotalAdjSystems"
,dcs."Assets"
,dcs."AdjAssets"
,dcs."TotalCritical+High"
,dcs."Critical Vulnerabilities"
,dcs."Critical: <= 15 days"
,dcs."Unique Critical: > 15 <= 60 days"
,dcs."Critical: <= 30 days"
,dcs."Unique Critical: > 30 <= 60 days"
,dcs."Critical: > 30 <= 60 days"
,dcs."Unique Critical: > 60 days"
,dcs."Critical: > 60 days"
,dcs."High Vulnerabilities"
,dcs."High: <= 30 days"
,dcs."Unique High: > 30 <= 60 days"
,dcs."High: > 30 <= 60 days"
,dcs."Unique High: > 60 days"
,dcs."High: > 60 days"
,dcs."VulCritical_gte15days"
,dcs."VulRaw"
,dcs."VulRaw_Critical"
,dcs."VulRaw_High"
,dcs."VulRaw_Low"
,dcs."VulRaw_Medium"
,dcs."VulUniqueCritical_gte15days"
,dcs."HWAMRawAWS"
,dcs."HWAMRawBigFix"
,dcs."HWAMRawForeScout"
FROM CORE.REPORT_IDS r
JOIN (SELECT REPORT_ID
    ,SUM(OperationalSystems) as "OperationalSystems"
	,SUM(Systems) as "TotalSystems"
	,SUM(Systems) as "TotalAdjSystems"
	,SUM(Assets) as "Assets"
	,SUM(Assets) as "AdjAssets"
	,SUM((VulCritical + VulHigh)) as "TotalCritical+High"
	,SUM(VulCritical) as "Critical Vulnerabilities"
	,SUM(VulCritical_lte15days) as "Critical: <= 15 days"
	,SUM(VulUniqueCritical_gt15_lte60days) as "Unique Critical: > 15 <= 60 days"
	,SUM(VulCritical_lte30days) as "Critical: <= 30 days"
	,SUM(VulUniqueCritical_gt30_lte60days) as "Unique Critical: > 30 <= 60 days"
	,SUM(VulCritical_gt30_lte60days) as "Critical: > 30 <= 60 days"
	,SUM(VulUniqueCritical_gt60days) as "Unique Critical: > 60 days"
	,SUM(VulCritical_gt60days) as "Critical: > 60 days"
	,SUM(VulHigh) as "High Vulnerabilities"
	,SUM(VulHigh_lte30days) as "High: <= 30 days"
	,SUM(VulUniqueHigh_gt30_lte60days) as "Unique High: > 30 <= 60 days"
	,SUM(VulHigh_gt30_lte60days) as "High: > 30 <= 60 days"
	,SUM(VulUniqueHigh_gt60days) as "Unique High: > 60 days"
	,SUM(VulHigh_gt60days) as "High: > 60 days"
	,SUM(VulCritical_gte15days) as "VulCritical_gte15days"
	,SUM(VulRaw) as "VulRaw"
	,SUM(VulRaw_Critical) as "VulRaw_Critical"
	,SUM(VulRaw_High) as "VulRaw_High"
	,SUM(VulRaw_Low) as "VulRaw_Low"
	,SUM(VulRaw_Medium) as "VulRaw_Medium"
	,SUM(VulUniqueCritical_gte15days) as "VulUniqueCritical_gte15days"
	,SUM(HWAMRawAWS) as "HWAMRawAWS"
	,SUM(HWAMRawBigFix) as "HWAMRawBigFix"
	,SUM(HWAMRawForeScout) as "HWAMRawForeScout"
	FROM CORE.DATACENTERSUMMARY
    GROUP BY REPORT_ID) dcs on dcs.REPORT_ID = r.REPORT_ID
ORDER BY cast(r.REPORT_DATE as date) desc
;