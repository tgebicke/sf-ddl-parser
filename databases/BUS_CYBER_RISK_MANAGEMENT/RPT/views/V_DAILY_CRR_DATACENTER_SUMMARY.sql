create or replace view V_DAILY_CRR_DATACENTER_SUMMARY(
	"DataCenterAcronym",
	"CommonName",
	"TotalSystems",
	"TotalAdjSystems",
	"TotalAssets",
	"TotalAdjAssets",
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
	"datacenter_id"
) COMMENT='Daily wise Summarized Cyber risk data by data center '
 as
select  
dc.acronym as "DataCenterAcronym"
,dc.CommonName as "CommonName"
,dcs.Systems as "TotalSystems"
,dcs.Systems as "TotalAdjSystems"
,dcs.Assets as "TotalAssets"
,dcs.Assets as "TotalAdjAssets"
,(dcs.VulCritical + dcs.VulHigh) as "TotalCritical+High"
,dcs.VulCritical  as "Critical Vulnerabilities"
,dcs.VulCritical_lte15days  as "Critical: <= 15 days"
,dcs.VulUniqueCritical_gt15_lte60days as "Unique Critical: > 15 <= 60 days"
,dcs.VulCritical_lte30days  as "Critical: <= 30 days"
,dcs.VulUniqueCritical_gt30_lte60days  as "Unique Critical: > 30 <= 60 days"
,dcs.VulCritical_gt30_lte60days  as "Critical: > 30 <= 60 days"
,dcs.VulUniqueCritical_gt60days  as "Unique Critical: > 60 days"
,dcs.VulCritical_gt60days  as "Critical: > 60 days"
,dcs.VulHigh  as "High Vulnerabilities"
,dcs.VulHigh_lte30days  as "High: <= 30 days"
,dcs.VulUniqueHigh_gt30_lte60days  as "Unique High: > 30 <= 60 days"
,dcs.VulHigh_gt30_lte60days  as "High: > 30 <= 60 days"
,dcs.VulUniqueHigh_gt60days  as "Unique High: > 60 days"
,dcs.VulHigh_gt60days  as "High: > 60 days"
,dc.SYSTEM_ID as "datacenter_id"
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.DataCenterSummary dcs on dcs.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = dcs.DATACENTER_ID
ORDER BY dc.CommonName;