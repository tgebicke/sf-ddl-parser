create or replace view V_DCRR_DASHBOARD(
	ACRONYM,
	COMPONENT_ACRONYM,
	HVASTATUS,
	MEFSTATUS,
	IS_MARKETPLACE,
	UNIQ_CRIT_15_60,
	TOT_CRIT_15_60,
	UNIQ_CRIT_60,
	TOT_CRIT_60,
	UNIQ_IGH_15_60,
	TOT_HIGH_15_60,
	UNIQ_HIGH_60,
	TOT_HIGH_60,
	HWAM_COUNT,
	CONTINGENCYEXPIRATIONDATE,
	DATE_AUTH_MEMO_EXPIRES,
	GROUP_ACRONYM,
	TLC_PHASE,
	OVER_DUE,
	PENTEST_COUNT,
	ASSETRISKTOLERANCE,
	RESIDUALRISK,
	VULNRISKTOLERANCE,
	RESILIENCYSCORE,
	OA_STATUS,
	TOT_CRIT_VULNS,
	TOT_HIGH_VULNS,
	REM_CNT,
	OPN_CNT,
	REFRESHDATE
) COMMENT='DCRR dashboard data'
 as
SELECT s.acronym,s.component_acronym,s.HVAStatus,s.MEFStatus,s.Is_MarketPlace,
  ss."Unique Critical: > 15 <= 60 days" as uniq_crit_15_60,
  ss."Critical: > 15 <= 60 days" as tot_crit_15_60,
  ss."Unique Critical: > 60 days" as uniq_crit_60,
  ss."Critical: > 60 days" as tot_crit_60,
  ss."Unique High: > 30 <= 60 days" as uniq_igh_15_60,
  ss."High: > 30 <= 60 days" as tot_high_15_60,
  ss."Unique High: > 60 days" as uniq_high_60,
  ss."High: > 60 days" as tot_high_60,
  0 as HWAM_COUNT,  --ss.Total_Assets as HWAM_COUNT,
  s.Next_Required_CP_Test_Date ContingencyExpirationDate,
  s.Date_Auth_Memo_Expires,
  s.Group_Acronym,
  ss."TLC_Phase",
  COALESCE(od.Over_due, 0) as Over_due,
  COALESCE(pentest_count, 0) pentest_count,
  summ.AssetRiskTolerance,
  summ.ResidualRisk,
  summ.VulnRiskTolerance,
  summ.resiliencyscore,
  s.OA_Status,
  ss."Critical Vulnerabilities" as tot_crit_vulns,
  ss."High Vulnerabilities" as tot_high_vulns,
  coalesce(summ.KEV_Open,0)+coalesce(summ.KEV_Reopened,0) as rem_cnt,
  summ.KEV_Fixed_MonthToDate as Opn_cnt,
current_date() as refreshdate
  
FROM rpt.V_CyberRisk_System_Summary ss 
left outer join CORE.VW_SYSTEMS s on s.SYSTEM_ID = ss."primary_fisma_id"
  
left outer join (select SYSTEM_ID,ResidualRisk,VulnRiskTolerance,AssetRiskTolerance,resiliencyscore, KEV_Open, KEV_Reopened, KEV_Fixed_MonthToDate 
    from CORE.VW_SYSTEMSUMMARY
    where REPORT_ID in (select REPORT_ID FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)))) summ on summ.SYSTEM_ID = ss."primary_fisma_id"
      
left outer join (select SYSTEM_ID, count(*) as pentest_count 
    from rpt.V_CRMP_Pentest where "Weakness_Risk_Level" = 'High' and "Overall_Status" in ('Delayed','Ongoing','Draft') -- 230928 quoted "Weakness_Risk_Level" and "Overall_Status"
  group by SYSTEM_ID) pentest on pentest.SYSTEM_ID = ss."primary_fisma_id"

left outer join (select p."CFACTS_UID" as SYSTEM_ID, Count(p."POA&M ID") Over_due -- 230928 replaced SYSTEM_ID with "CFACTS_UID" and POAM_ID with "POA&M ID"
    from rpt.V_POAMS_MonthEndSnapshot p
    join CORE.VW_SYSTEMS s on s.SYSTEM_ID = p."CFACTS_UID"
    WHERE p."Overall_Status" in ('Delayed') -- 230928 quoted "Overall_Status"
        AND p."Estimated_Completion_Date" <= (select REPORT_DATE FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1))) -- 230928 quoted "Estimated_Completion_Date"
        AND p."Weakness_Risk_Level" = 'High' AND s.HVAStatus='Yes' AND s.TLC_Phase<>'Retire' -- 230928 quoted "Weakness_Risk_Level"
    GROUP BY p."CFACTS_UID") od on od.SYSTEM_ID = ss."primary_fisma_id"
;