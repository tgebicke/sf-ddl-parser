create or replace view V_SYSTEMSUMMARY_DCRR_SYSTEMS(
	CONTROL_SET_VERSION_NUMBER_SYSTEM_PROVID,
	CFACTS_UID,
	COMPONENT_ACRONYM,
	ACRONYM,
	BUSINESS_OWNER,
	PRIMARY_ISSO,
	PRIMARY_OPERATING_LOCATION,
	SDM,
	TLC_PHASE,
	ISSO,
	CRA,
	GROUP_NAME,
	DIVISION_NAME,
	GROUP_ACRONYM,
	IS_MARKETPLACE,
	HVASTATUS,
	MEFSTATUS,
	AUTHORIZATION_PACKAGE,
	CONTINGENCYEXPIRATIONDATE,
	NEXT_REQUIRED_CP_TEST_DATE,
	CP_TEST_DATE,
	AUTH_DECISION,
	DATE_AUTH_MEMO_EXPIRES,
	IS_OA_READY,
	OA_STATUS,
	REM_CNT,
	KEV_OPEN,
	KEV_REOPENED,
	UNIQ_CRIT_15_60,
	UNIQ_CRIT_60,
	TOT_CRIT_60,
	UNIQ_IGH_15_60,
	TOT_HIGH_15_60,
	UNIQ_HIGH_60,
	TOT_HIGH_60,
	HWAM_COUNT,
	ASSETRISKTOLERANCE,
	RESIDUALRISK,
	VULNRISKTOLERANCE,
	RESILIENCYSCORE,
	TOT_CRIT_VULNS,
	TOT_HIGH_VULNS,
	REPORT_ID,
	REPORT_DATE,
	RANKK
) COMMENT='Used for Tableau in Dynamic Cyber Risk Dashboard : \nView contains System related information.'
 as
select
systems.Control_Set_Version_Number_System_Provid
,systems.system_id cfacts_uid
,systems.COMPONENT_ACRONYM
,systems.acronym
,systems.BUSINESS_OWNER
,systems.primary_isso
,systems.primary_operating_location
,systems.sdm
,systems.tlc_phase
,systems.isso
,systems.cra
,systems.GROUP_NAME
,systems.DIVISION_NAME
,systems.Group_Acronym
,systems.Is_MarketPlace
,systems.HVAStatus
,systems.MEFStatus
,systems.Authorization_Package
,systems.ContingencyExpirationDate
,systems.Next_Required_CP_Test_Date
,systems.cp_test_date
,systems.Auth_Decision
,systems.Date_Auth_Memo_Expires
,systems.Is_OA_Ready
,systems.OA_Status
,summary.KEV_Fixed_MonthToDate rem_cnt
,summary.KEV_Open
,summary.KEV_Reopened 
,summary.VulUniqueCritical_gt15_lte60days as uniq_crit_15_60
,summary.VulUniqueCritical_gt60days as uniq_crit_60
,summary.VulCritical_gt60days  as tot_crit_60
,summary.VulUniqueHigh_gt30_lte60days  as uniq_igh_15_60
,summary.VulHigh_gt30_lte60days as tot_high_15_60
,summary.VulUniqueHigh_gt60days as uniq_high_60
,summary.VulHigh_gt60days as tot_high_60
,summary.Assets HWAM_COUNT
,summary.AssetRiskTolerance
,summary.ResidualRisk
,summary.VulnRiskTolerance
,summary.resiliencyscore
,summary.VulCritical as tot_crit_vulns
,summary.VulHigh as tot_high_vulns
,snap.REPORT_ID
,snap.Report_Date
,dense_rank()over(order by snap.REPORT_ID desc) as rankk
 from CORE.VW_SYSTEMSUMMARY summary
join (SELECT REPORT_ID,Report_Date FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0))
UNION
SELECT REPORT_ID,Report_Date FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1))) snap on snap.REPORT_ID=summary.REPORT_ID
right outer join CORE.vw_systems systems on (summary.system_id = systems.system_id) 
where systems.IS_PHANTOMSYSTEM = 0 and systems.IS_EXCLUDEFROMREPORTING = 0;