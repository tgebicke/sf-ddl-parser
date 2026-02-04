create or replace view V_CYBERRISK_SYSTEM_SUMMARY(
	"Group_Acronym",
	"Component_Acronym",
	"System",
	"DataCenterAcronym",
	"CommonName",
	"System_DateCreated",
	"TLC_Phase",
	"PriorCRR_Assets",
	"Total Assets",
	"Delta_Assets",
	"TotalAdjAssets",
	"Total Vulnerabilites",
	"PriorCRR_VulCritical",
	"Critical Vulnerabilities",
	"Delta_VulCritical",
	"Critical: <= 15 days",
	"Unique Critical: > 15 <= 60 days",
	"Critical: > 15 <= 60 days",
	"Critical: <= 30 days",
	"Unique Critical: > 30 <= 60 days",
	"Critical: > 30 <= 60 days",
	"Unique Critical: > 60 days",
	"Critical: > 60 days",
	"PriorCRR_VulHigh",
	"High Vulnerabilities",
	"Delta_VulHigh",
	"High: <= 30 days",
	"Unique High: > 30 <= 60 days",
	"High: > 30 <= 60 days",
	"Unique High: > 60 days",
	"High: > 60 days",
	"VulMedium",
	"VulUniqueMedium",
	"VulLow",
	"VulUniqueLow",
	"KEV_Open",
	"KEV_Reopened",
	"KEV_Fixed_MonthToDate",
	"datacenter_id",
	"primary_fisma_id",
	"FK_DataCenter_ID",
	"FK_primary_fisma_id",
	"Primary_Operating_Location",
	"VulCritical_gte15days"
) COMMENT='Contains Summarized data for various data categories at FISMA SYSTEM level'
 as
select 
s.Group_Acronym as "Group_Acronym"
,s.Component_Acronym as "Component_Acronym"
,s.Acronym as "System"
,dc.Acronym as "DataCenterAcronym"
,s.CommonName as "CommonName"
,s.INSERT_DATE::VARCHAR as "System_DateCreated"
,sHist.TLC_Phase as "TLC_Phase"
,coalesce(PriorSS.Assets,0) as "PriorCRR_Assets"
,ss.Assets as "Total Assets"
,(ss.Assets - coalesce(PriorSS.Assets,0)) as "Delta_Assets"
,ss.Assets as "TotalAdjAssets"
,(ss.VulCritical + ss.VulHigh) as "Total Vulnerabilites"
,coalesce(PriorSS.VulCritical,0) as "PriorCRR_VulCritical"
,ss.VulCritical as "Critical Vulnerabilities"
,(ss.VulCritical - coalesce(PriorSS.VulCritical,0)) as "Delta_VulCritical"
,ss.VulCritical_lte15days as "Critical: <= 15 days"
,ss.VulUniqueCritical_gt15_lte60days as "Unique Critical: > 15 <= 60 days"
,ss.VulCritical_gt15_lte60days as "Critical: > 15 <= 60 days"
,ss.VulCritical_lte30days as "Critical: <= 30 days"
,ss.VulUniqueCritical_gt30_lte60days as "Unique Critical: > 30 <= 60 days"
,ss.VulCritical_gt30_lte60days as "Critical: > 30 <= 60 days"
,ss.VulUniqueCritical_gt60days as "Unique Critical: > 60 days"
,ss.VulCritical_gt60days as "Critical: > 60 days"
,coalesce(PriorSS.VulHigh,0) as "PriorCRR_VulHigh"
,ss.VulHigh as "High Vulnerabilities"
,(ss.VulHigh - coalesce(PriorSS.VulHigh,0)) as "Delta_VulHigh"
,ss.VulHigh_lte30days as "High: <= 30 days"
,ss.VulUniqueHigh_gt30_lte60days as "Unique High: > 30 <= 60 days"
,ss.VulHigh_gt30_lte60days as "High: > 30 <= 60 days"
,ss.VulUniqueHigh_gt60days as "Unique High: > 60 days"
,ss.VulHigh_gt60days as "High: > 60 days"
,ss.VulMedium as "VulMedium"
,ss.VulUniqueMedium as "VulUniqueMedium"
,ss.VulLow as "VulLow"
,ss.VulUniqueLow as "VulUniqueLow"
,ss.KEV_Open as "KEV_Open"
,ss.KEV_Reopened as "KEV_Reopened"
,ss.KEV_Fixed_MonthToDate as "KEV_Fixed_MonthToDate"
,dc.SYSTEM_ID as "datacenter_id"
,s.SYSTEM_ID as "primary_fisma_id"
,dc.SYSTEM_ID as "FK_DataCenter_ID"
,s.SYSTEM_ID as "FK_primary_fisma_id"
,s.Primary_Operating_Location as "Primary_Operating_Location"
,ss.VULCRITICAL_GTE15DAYS as "VulCritical_gte15days" -- 230829
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) r
-- 240222 CR840 chg from table SYSTEMSUMMARY to view VW_SYSTEMSUMMARY
JOIN CORE.VW_SYSTEMSUMMARY ss on ss.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = ss.SYSTEM_ID
JOIN CORE.SystemsHist sHist on sHist.REPORT_ID = r.REPORT_ID and sHist.SYSTEM_ID = s.SYSTEM_ID
-- 240222 CR840 chg from table SYSTEMSUMMARY to view VW_SYSTEMSUMMARY
LEFT OUTER JOIN CORE.VW_SYSTEMSUMMARY PriorSS on PriorSS.SYSTEM_ID = s.SYSTEM_ID and PriorSS.REPORT_ID = (select MAX(REPORT_ID) PriorCRR from CORE.REPORT_IDS where IS_ENDOFMONTH = 1 and REPORT_ID < (select REPORT_ID from TABLE(CORE.FN_CRM_GET_REPORT_ID(1))))
LEFT OUTER JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = s.PRIMARY_OPERATING_LOCATION_ID 
WHERE (ss.Assets > 0 or s.TLC_Phase <> 'Retire') 
ORDER BY s.Acronym
;