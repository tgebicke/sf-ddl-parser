create or replace view V_SYSTEMSUMMARY(
	"ReportDate",
	"Is_endOfMonth",
	"ComponentAcronym",
	"DivisionAcronym",
	"GroupAcronym",
	"PrimaryOperatingLocation",
	"SystemAcronym",
	"SystemCommonName",
	CFACTS_UID,
	IS_MARKETPLACE,
	"Assets",
	"VulCritical",
	"VulCritical_gt30_lte60days",
	"VulCritical_gt60days",
	"VulCritical_gte15days",
	"VulCritical_lte15days",
	"VulCritical_lte30days",
	"VulHigh",
	"VulHigh_gt30_lte60days",
	"VulHigh_gt60days",
	"VulHigh_lte30days",
	"VulRaw",
	"VulRaw_Critical",
	"VulRaw_High",
	"VulRaw_Low",
	"VulRaw_Medium",
	"VulUniqueCritical_gt15_lte60days",
	"VulUniqueCritical_gt30_lte60days",
	"VulUniqueCritical_gt60days",
	"VulUniqueCritical_gte15days",
	"VulUniqueHigh_gt30_lte60days",
	"VulUniqueHigh_gt60days",
	"HWAMRawAWS",
	"HWAMRawBigFix",
	"HWAMRawForeScout",
	"VulDeleted",
	"VulMedium",
	"VulLow",
	"VulUniqueMedium",
	"VulUniqueLow",
	"AssetRiskTolerance",
	"ResidualRisk",
	"ResiliencyScore",
	"PrevAssets",
	"VulnRiskTolerance",
	"FK_ReportID",
	"FK_SystemID",
	FISMA_ID,
	"SystemSummaryPrimaryKey",
	"Control_Set_Version_Number_System_Provid",
	"KEV_Open",
	"KEV_Reopened",
	"KEV_Fixed_MonthToDate",
	AUTHORIZATION_PACKAGE,
	KEV_FIXED_TODAY,
	SCANNABLEASSETS,
	VULCRITICALREMEDIATED,
	VULHIGHREMEDIATED,
	VULUNIQUECRITICAL_GT15_LTE60DAYS
) WITH ROW ACCESS POLICY ACCESS_CONTROL.SECURITY.CRM_RPT_FISMA_POLICY ON (CFACTS_UID)
 COMMENT='System level summary data for all report_id to show history of system changes.'
 as
select ss.REPORT_DATE as "ReportDate"
,ss.IS_ENDOFMONTH as "Is_endOfMonth"
,s.COMPONENT_ACRONYM as "ComponentAcronym"
,s.DIVISION_ACRONYM as "DivisionAcronym"
,s.GROUP_ACRONYM as "GroupAcronym"
,s.PRIMARY_OPERATING_LOCATION_ACRONYM as "PrimaryOperatingLocation"
,s.ACRONYM as "SystemAcronym"
,s.COMMONNAME as "SystemCommonName"
,ss.SYSTEM_ID as "CFACTS_UID"
,s.IS_MARKETPLACE
,ss.ASSETS as "Assets"
,ss.VULCRITICAL as "VulCritical"
,ss.VULUNIQUECRITICAL_GT30_LTE60DAYS as "VulCritical_gt30_lte60days"
,ss.VULCRITICAL_GT60DAYS as "VulCritical_gt60days"
,ss.VULCRITICAL_GTE15DAYS as "VulCritical_gte15days"
,ss.VULCRITICAL_LTE15DAYS as "VulCritical_lte15days"
,ss.VULCRITICAL_LTE30DAYS as "VulCritical_lte30days"
,ss.VULHIGH as "VulHigh"
,ss.VULHIGH_GT30_LTE60DAYS as "VulHigh_gt30_lte60days"
,ss.VULHIGH_GT60DAYS as "VulHigh_gt60days"
,ss.VULHIGH_LTE30DAYS as "VulHigh_lte30days"
,ss.VULRAW as "VulRaw"
,ss.VULRAW_CRITICAL as "VulRaw_Critical"
,ss.VULRAW_HIGH as "VulRaw_High"
,ss.VULRAW_LOW as "VulRaw_Low"
,ss.VULRAW_MEDIUM as "VulRaw_Medium"
,ss.VULCRITICAL_GT15_LTE60DAYS as "VulUniqueCritical_gt15_lte60days"
,ss.VULCRITICAL_GT30_LTE60DAYS as "VulUniqueCritical_gt30_lte60days"
,ss.VULUNIQUECRITICAL_GT60DAYS as "VulUniqueCritical_gt60days"
,ss.VULUNIQUECRITICAL_GTE15DAYS as "VulUniqueCritical_gte15days"
,ss.VULUNIQUEHIGH_GT30_LTE60DAYS as "VulUniqueHigh_gt30_lte60days"
,ss.VULUNIQUEHIGH_GT60DAYS as "VulUniqueHigh_gt60days"
,ss.HWAMRAWAWS as "HWAMRawAWS"
,ss.HWAMRAWBIGFIX as "HWAMRawBigFix"
,ss.HWAMRAWFORESCOUT as "HWAMRawForeScout"
,ss.VULDELETED as "VulDeleted"
,ss.VULMEDIUM as "VulMedium"
,ss.VULLOW as "VulLow"
,ss.VULUNIQUEMEDIUM as "VulUniqueMedium"
,ss.VULUNIQUELOW as "VulUniqueLow"
,ss.ASSETRISKTOLERANCE as "AssetRiskTolerance"
,ss.RESIDUALRISK as "ResidualRisk"
,ss.RESILIENCYSCORE as "ResiliencyScore"
,ss.PREVASSETS as "PrevAssets"
,ss.VULNRISKTOLERANCE as "VulnRiskTolerance"
,ss.REPORT_ID as "FK_ReportID"
,ss.SYSTEM_ID as "FK_SystemID"
,ss.SYSTEM_ID as FISMA_ID
,ss.ID as "SystemSummaryPrimaryKey"
,s.CONTROL_SET_VERSION_NUMBER_SYSTEM_PROVID as "Control_Set_Version_Number_System_Provid"
,ss.KEV_OPEN as "KEV_Open"
,ss.KEV_REOPENED as "KEV_Reopened"
,ss.KEV_FIXED_MONTHTODATE as "KEV_Fixed_MonthToDate"
,s.AUTHORIZATION_PACKAGE as AUTHORIZATION_PACKAGE
,ss.KEV_FIXED_TODAY as KEV_FIXED_TODAY
,ss.SCANNABLEASSETS as SCANNABLEASSETS
,0 as VULCRITICALREMEDIATED -- 240222 CR840 VW_SYSTEMSUMMARY no longer has this field. It was never populated.
,0 as VULHIGHREMEDIATED -- 240222 CR840 VW_SYSTEMSUMMARY no longer has this 
,ss.VULUNIQUECRITICAL_GT15_LTE60DAYS as VULUNIQUECRITICAL_GT15_LTE60DAYS
FROM CORE.VW_SYSTEMSUMMARY ss
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = ss.SYSTEM_ID
;