create or replace view VW_DAILY_CRR_DATACENTER_SUMMARY(
	DATACENTERACRONYM,
	COMMONNAME,
	TOTALSYSTEMS,
	TOTALASSETS,
	TOTALCRITICAL_HIGH,
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
	DATACENTER_ID
) COMMENT='Returns multiple vuln catagory daily summary for every datacenter.'
 as
select 
dc.acronym as DataCenterAcronym
,dc.CommonName
,dcs.Systems as TotalSystems
--,dcs.AdjSystems as TotalAdjSystems
,dcs.Assets as TotalAssets
--,dcs.AdjAssets as TotalAdjAssets
,(dcs.VulCritical + dcs.VulHigh) as TotalCritical_High
,dcs.VulCritical as "Critical Vulnerabilities"
,dcs.VulCritical_lte15days as "Critical: <= 15 days" -- 200821 0945
,dcs.VulUniqueCritical_gt15_lte60days as "Unique Critical: > 15 <= 60 days" -- 200821 0945
,dcs.VulCritical_lte30days as "Critical: <= 30 days"
,dcs.VulUniqueCritical_gt30_lte60days as "Unique Critical: > 30 <= 60 days"
,dcs.VulCritical_gt30_lte60days as "Critical: > 30 <= 60 days"
,dcs.VulUniqueCritical_gt60days as "Unique Critical: > 60 days"
,dcs.VulCritical_gt60days as "Critical: > 60 days"
,dcs.VulHigh as "High Vulnerabilities"
,dcs.VulHigh_lte30days as "High: <= 30 days"
,dcs.VulUniqueHigh_gt30_lte60days as "Unique High: > 30 <= 60 days"
,dcs.VulHigh_gt30_lte60days as "High: > 30 <= 60 days"
,dcs.VulUniqueHigh_gt60days as "Unique High: > 60 days"
,dcs.VulHigh_gt60days as "High: > 60 days"
,dc.SYSTEM_ID as datacenter_id
FROM CORE.VW_Systems  dc
JOIN CORE.DataCenterSummary dcs on dcs.DATACENTER_ID = dc.SYSTEM_ID and dcs.REPORT_ID = (select REPORT_ID from table(CORE.FN_CRM_GET_REPORT_ID(0))) 
ORDER BY dc.CommonName;