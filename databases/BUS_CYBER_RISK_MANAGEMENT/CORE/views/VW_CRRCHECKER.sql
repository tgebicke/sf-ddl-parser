create or replace view VW_CRRCHECKER(
	"View Name",
	TOTALSYSTEMS,
	ASSETS,
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
	"VulLow"
) COMMENT='Compare output of CyberRisk related views.'
 as
with Detail AS(
select FISMAseverity, count(1) as Total  from RPT.V_CyberRisk_VUL_Detail group by FISMAseverity
)
select 
    'rpt.V_CyberRisk_Month_Trend' as "View Name",
    "TotalSystems",
    "Assets",
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
	null as "VulLow" -- 230829 legacy had SUM([VulLow])  [VulRaw]
from RPT.V_CyberRisk_Month_Trend where "ReportDate"= (SELECT cast(REPORT_DATE as date) FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)))
UNION ALL
select 
'rpt.V_CyberRisk_DataCenter_Summary' as "View Name"
,SUM("TotalSystems") as "TotalSystems"
,SUM("TotalAssets") as "Assets"
,SUM("TotalCritical+High") as "TotalCritical+High"
,SUM("Critical Vulnerabilities") as "Critical Vulnerabilities"
,SUM("Critical: <= 15 days") as "Critical: <= 15 days"
,SUM("Unique Critical: > 15 <= 60 days") as "Unique Critical: > 15 <= 60 days"
,SUM("Critical: <= 30 days") as "Critical: <= 30 days"
,SUM("Unique Critical: > 30 <= 60 days") as "Unique Critical: > 30 <= 60 days"
,SUM("Critical: > 30 <= 60 days") as "Critical: > 30 <= 60 days"
,SUM("Unique Critical: > 60 days") as "Unique Critical: > 60 days"
,SUM("Critical: > 60 days") as "Critical: > 60 days"
,SUM("High Vulnerabilities") as "High Vulnerabilities"
,SUM("High: <= 30 days") as "High: <= 30 days"
,SUM("Unique High: > 30 <= 60 days") as "Unique High: > 30 <= 60 days"
,SUM("High: > 30 <= 60 days") as "High: > 30 <= 60 days"
,SUM("Unique High: > 60 days") as "Unique High: > 60 days"
,SUM("High: > 60 days") as "High: > 60 days"
,SUM("VulCritical_gte15days") as "VulCritical_gte15days" -- 230829 in legacy it is;;;null as "VulCritical_gte15days" -- 230829 in legacy it is: SUM([VulMedium])  [VulCritical_gte15days]
,SUM("VulLow") as "VulLow" -- 230829 in legacy the alias was VulRaw
from RPT.V_CyberRisk_DataCenter_Summary 
UNION ALL
select 
'rpt.V_CyberRisk_System_Summary' as "View Name"
,null  "TotalSystems"
,SUM("Total Assets") as "Assets"
,null  "TotalCritical+High"
,SUM("Critical Vulnerabilities") as "Critical Vulnerabilities"
,SUM("Critical: <= 15 days") as "Critical: <= 15 days"
,SUM("Unique Critical: > 15 <= 60 days") as "Unique Critical: > 15 <= 60 days"
,SUM("Critical: <= 30 days") as "Critical: <= 30 days"
,SUM("Unique Critical: > 30 <= 60 days") as "Unique Critical: > 30 <= 60 days"
,SUM("Critical: > 30 <= 60 days") as "Critical: > 30 <= 60 days"
,SUM("Unique Critical: > 60 days") as "Unique Critical: > 60 days"
,SUM("Critical: > 60 days") as "Critical: > 60 days"
,SUM("High Vulnerabilities") as "High Vulnerabilities"
,SUM("High: <= 30 days") as "High: <= 30 days"
,SUM("Unique High: > 30 <= 60 days") as "Unique High: > 30 <= 60 days"
,SUM("High: > 30 <= 60 days") as "High: > 30 <= 60 days"
,SUM("Unique High: > 60 days") as "Unique High: > 60 days"
,SUM("High: > 60 days") as "High: > 60 days"
,SUM("VulCritical_gte15days") as "VulCritical_gte15days" -- 230829 in legacy it is: SUM([VulMedium])  [VulCritical_gte15days]
,SUM("VulLow") as "VulLow" -- 230829 in legacy the alias was VulRaw
from RPT.V_CyberRisk_System_Summary 
UNION ALL
select 
'CORE.VW_CyberRisk_System_DataCenter_Summary' as "View Name"
,null  "TotalSystems"
,SUM("Total_Assets") as "Assets"
,null  "TotalCritical+High"
,SUM("Critical_Vulnerabilities") as "Critical Vulnerabilities"
,null  "Critical: <= 15 days"
,null  "Unique Critical: > 15 <= 60 days"
,null  "Critical: <= 30 days"
,null "Unique Critical: > 30 <= 60 days"
,null "Critical: > 30 <= 60 days"
,null "Unique Critical: > 60 days"
,null  "Critical: > 60 days"
,SUM("High_Vulnerabilities") as "High Vulnerabilities"
,null "High: <= 30 days"
,null  "Unique High: > 30 <= 60 days"
,null "High: > 30 <= 60 days"
,null "Unique High: > 60 days"
,null "High: > 60 days"
,null  "VulCritical_gte15days"
,null  "VulLow"
from core.VW_CyberRisk_System_DataCenter_Summary 
UNION ALL
select 
'rpt.V_CyberRisk_System_Devices' as "View Name"
,null  "TotalSystems"
,SUM(TotalAssets) as "Assets"
,null  "TotalCritical+High"
,null  "Critical Vulnerabilities"
,null  "Critical: <= 15 days"
,null  "Unique Critical: > 15 <= 60 days"
,null  "Critical: <= 30 days"
,null  "Unique Critical: > 30 <= 60 days"
,null  "Critical: > 30 <= 60 days"
,null  "Unique Critical: > 60 days"
,null  "Critical: > 60 days"
,null  "High Vulnerabilities"
,null  "High: <= 30 days"
,null  "Unique High: > 30 <= 60 days"
,null  "High: > 30 <= 60 days"
,null  "Unique High: > 60 days"
,null  "High: > 60 days"
,null  "VulCritical_gte15days"
,null  "VulLow" -- 230829 was VulRaw
from RPT.V_CyberRisk_System_Devices 
UNION ALL
select 
'rpt.V_CyberRisk_VUL_Detail' as "View Name"
,null  "TotalSystems"
,null  "Assets"
,null  "TotalCritical+High"
,(select Total from Detail where FISMAseverity='Critical') as "Critical Vulnerabilities"
,null  "Critical: <= 15 days"
,null  "Unique Critical: > 15 <= 60 days"
,null  "Critical: <= 30 days"
,null "Unique Critical: > 30 <= 60 days"
,null "Critical: > 30 <= 60 days"
,null "Unique Critical: > 60 days"
,null  "Critical: > 60 days"
,(select Total from Detail where FISMAseverity='High') as "High Vulnerabilities"
,null "High: <= 30 days"
,null  "Unique High: > 30 <= 60 days"
,null "High: > 30 <= 60 days"
,null "Unique High: > 60 days"
,null "High: > 60 days"
,null "VulCritical_gte15days" -- 230829 was (select Total from Detail where FISMAseverity='Medium') as "VulCritical_gte15days"
,(select Total from Detail where FISMAseverity='Low') as "VulLow";