create or replace view V_SYSTEMSUMMARY_MCRR_SYSTEMS(
	ACRONYM,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	GROUP_NAME,
	DIVISION_ACRONYM,
	DIVISIONNAME,
	AUTHORIZATION_PACKAGE,
	BUSINESS_OWNER,
	CONTINGENCYEXPIRATIONDATE,
	NEXT_REQUIRED_CP_TEST_DATE,
	CP_TEST_DATE,
	AUTH_DECISION,
	DATE_AUTH_MEMO_EXPIRES,
	IS_OA_READY,
	OA_STATUS,
	HVASTATUS,
	MEFSTATUS,
	IS_MARKETPLACE,
	TLC_PHASE,
	PRIMARY_ISSO,
	PRIMARY_OPERATING_LOCATION,
	SDM,
	ISSO,
	CRA,
	CFACTS_UID,
	CONTROL_SET_VERSION_NUMBER_SYSTEM_PROVID,
	REPORTDATE,
	ASSETS,
	VULCRITICAL,
	VULCRITICAL_GT30_LTE60DAYS,
	VULCRITICAL_GT60DAYS,
	VULCRITICAL_GTE15DAYS,
	VULCRITICAL_LTE15DAYS,
	VULCRITICAL_LTE30DAYS,
	VULHIGH,
	VULHIGH_GT30_LTE60DAYS,
	VULHIGH_GT60DAYS,
	VULHIGH_LTE30DAYS,
	VULRAW,
	VULRAW_CRITICAL,
	VULRAW_HIGH,
	VULRAW_LOW,
	VULRAW_MEDIUM,
	VULUNIQUECRITICAL_GT15_LTE60DAYS,
	VULUNIQUECRITICAL_GT30_LTE60DAYS,
	VULUNIQUECRITICAL_GT60DAYS,
	VULUNIQUECRITICAL_GTE15DAYS,
	VULUNIQUEHIGH_GT30_LTE60DAYS,
	VULUNIQUEHIGH_GT60DAYS,
	HWAMRAWAWS,
	HWAMRAWBIGFIX,
	HWAMRAWFORESCOUT,
	VULDELETED,
	VULMEDIUM,
	VULLOW,
	VULUNIQUEMEDIUM,
	VULUNIQUELOW,
	ASSETRISKTOLERANCE,
	RESIDUALRISK,
	RESILIENCYSCORE,
	PREVASSETS,
	VULNRISKTOLERANCE,
	TOTALVRT,
	VULCRITICAL_GT15_LTE60DAYS,
	KEV_OPEN,
	KEV_REOPENED,
	KEV_FIXED_TODAY,
	KEV_FIXED_MONTHTODATE,
	REPORT_ID,
	SYSTEM_ID,
	SYSTEMSUMMARYPRIMARYKEY,
	VULCRITICALREMEDIATED,
	VULHIGHREMEDIATED,
	OVER_DUE,
	PENTEST_COUNT,
	RANKK,
	COMPONENT,
	GROUPS,
	SYSTEMS,
	REPORTNAME
) COMMENT='Contains system related information (OA Status/VRT/ART/CP Expiry/ATO/Business Owner etc)'
 as
select
  systems.Acronym
  ,systems.Component_Acronym
  ,systems.Group_Acronym
  ,systems.group_name
  ,systems.Division_Acronym
  ,systems.Division_Name DivisionName
  ,systems.Authorization_Package
  ,systems.Business_Owner
  ,systems.ContingencyExpirationDate
  ,systems.Next_Required_CP_Test_Date
  ,systems.CP_Test_Date
  ,systems.Auth_Decision
  ,systems.Date_Auth_Memo_Expires
  ,systems.Is_OA_Ready
  ,systems.OA_Status
  ,systems.HVAStatus
  ,systems.MEFStatus
  ,systems.Is_MarketPlace
  ,systems.TLC_Phase
  ,systems.Primary_ISSO
  ,systems.Primary_Operating_Location
  ,systems.sdm
  ,systems.isso
  ,systems.cra
  ,systems.cfacts_uid
  ,systems.Control_Set_Version_Number_System_Provid
  ,snap.REPORT_DATE as ReportDate
  ,Summary.assets
  ,Summary.vulcritical
  ,Summary.vulcritical_gt30_lte60days
  ,Summary.vulcritical_gt60days
  ,Summary.VulCritical_gte15days
  ,Summary.VulCritical_lte15days
  ,Summary.VulCritical_lte30days
  ,Summary.VulHigh
  ,Summary.VulHigh_gt30_lte60days
  ,Summary.VulHigh_gt60days
  ,Summary.VulHigh_lte30days
  ,Summary.VulRaw
  ,Summary.VulRaw_Critical
  ,Summary.VulRaw_High
  ,Summary.VulRaw_Low
  ,Summary.VulRaw_Medium
  ,Summary.VulUniqueCritical_gt15_lte60days
  ,Summary.VulUniqueCritical_gt30_lte60days
  ,Summary.VulUniqueCritical_gt60days
  ,Summary.VulUniqueCritical_gte15days
  ,Summary.VulUniqueHigh_gt30_lte60days
  ,Summary.VulUniqueHigh_gt60days
  ,Summary.hwamrawaws
  ,Summary.HWAMRawBigFix
  ,Summary.HWAMRawForeScout
  ,Summary.VulDeleted
  ,Summary.VulMedium
  ,Summary.VulLow
  ,Summary.VulUniqueMedium
  ,Summary.VulUniqueLow
  ,Summary.AssetRiskTolerance
  ,Summary.ResidualRisk
  ,Summary.ResiliencyScore
  ,Summary.PrevAssets
  ,Summary.VulnRiskTolerance
  ,summary.VulnRiskTolerance AS TotalVRT
  ,summary.VulCritical_gt15_lte60days
  ,summary.KEV_Open
  ,summary.KEV_Reopened
  ,summary.KEV_Fixed_Today
  ,summary.KEV_Fixed_MonthToDate
  ,Summary.report_id
  ,Summary.system_id
  ,Summary.ID AS SystemSummaryPrimaryKey
  ,0 as VULCRITICALREMEDIATED -- 240222 CR840 VW_SYSTEMSUMMARY no longer has this field. It was never populated.
  ,0 as VULHIGHREMEDIATED -- 240222 CR840 VW_SYSTEMSUMMARY no longer has this field. It was never populated.
  ,COALESCE(od.Over_due, 0) as Over_due
  ,COALESCE(pentest_count, 0) pentest_count
  ,dense_rank()over(order by ReportDate desc) as rankk
  ,Report_Name.Component
  ,Report_Name.Groups
  ,Report_Name.Systems
  ,Report_Name.ReportName
  from core.VW_SYSTEMSUMMARY summary
  join (select top 2 report_id,report_date from core.REPORT_IDS where is_endofmonth =1 order by REPORT_DATE desc) snap on snap.REPORT_ID = summary.report_id
  right outer join (select system_id, Acronym, Component_Acronym, Group_Acronym, group_name, Division_Acronym, DIVISION_NAME, Authorization_Package, 
  Business_Owner, ContingencyExpirationDate, Next_Required_CP_Test_Date, CP_Test_Date, Auth_Decision, Date_Auth_Memo_Expires, Is_OA_Ready, 
  OA_Status, HVAStatus, MEFStatus, Is_MarketPlace, TLC_Phase, Primary_ISSO, Primary_Operating_Location, sdm, isso, cra, system_id cfacts_uid,
  Control_Set_Version_Number_System_Provid from CORE.VW_SYSTEMS) systems on summary.system_id = systems.system_id
  left outer join (select "Acronym","Component_Acronym", count(*) as pentest_count from rpt.V_CRMP_PENTEST where "Weakness_Risk_Level" = 'High' and "Overall_Status" in ('Delayed','Ongoing','Draft')
  group by "Acronym","Component_Acronym") pentest on (systems.Acronym = pentest."Acronym" and systems.Component_Acronym = pentest."Component_Acronym")
    left outer join (select Count(P."POA&M ID") Over_due,s.Acronym,s.Component_Acronym from rpt.V_POAMS_MONTHENDSNAPSHOT P
  JOIN (Select Acronym, Component_Acronym, ARCHER_TRACKING_ID, HVAStatus, TLC_Phase from CORE.VW_SYSTEMS) s On s.ARCHER_TRACKING_ID= p."Archer_Tracking_ID"
  
  where
  	   "Overall_Status" in ('Delayed')
  	  AND "Estimated_Completion_Date" <= (select max(report_date) from core.VW_REPORTSNAPSHOTS where datacategory = 'CFACTS' and Is_endOfMonth =1)  --Added per Teresa's request
  	  AND "Weakness_Risk_Level" = 'High'
  	  and s.HVAStatus='Yes' and s.TLC_Phase<>'Retire'
  	  group by s.Acronym,s.Component_Acronym)od on  (systems.Acronym = od.Acronym and systems.Component_Acronym = od.Component_Acronym)
  LEFT JOIN (
  select * from rpt.CRR_COMPONENT_PARAMS
) Report_Name ON ((systems.Acronym = Report_Name.SYSTEMS) AND (systems.component_Acronym = Report_Name.COMPONENT) AND (systems.Group_Acronym = Report_Name.GROUPS));