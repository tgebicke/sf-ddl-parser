CREATE OR REPLACE PROCEDURE "SP_CRM_TESTFILES_MCRR"("P_ACHRONYM" VARCHAR(16777216))
RETURNS TABLE ()
LANGUAGE SQL
COMMENT='CRM stored procedure for MCRR'
EXECUTE AS OWNER
AS '
DECLARE
    res RESULTSET;
    res1 RESULTSET;
  BEGIN
    res := (
    select 
	params.ReportName,
	rptsummary.acronym,
	Months.report_id,
	Months.report_date,
    rptsummary.Assets,
    s.Next_Required_CP_Test_Date,
    s.component_acronym,
    s.Auth_Decision,
    s.Date_Auth_Memo_Expires,
    s.Is_OA_Ready,
    s.OA_Status,
	rptsummary.AssetRiskTolerance,
	rptsummary.ResidualRisk,
	rptsummary.ResiliencyScore,
	rptsummary.VulnRiskTolerance,
	css."Critical Vulnerabilities" as tot_crit_vulns,
	css."High Vulnerabilities" as tot_high_vulns,
	s.TLC_Phase,
	VULUNIQUECRITICAL_GT60DAYS, 
	VULCRITICAL_GT60DAYS ,
	VULUNIQUEHIGH_GT60DAYS , 
	VULHIGH_GT60DAYS ,
	VULUNIQUECRITICAL_GT15_LTE60DAYS , 
	VULCRITICAL_GT15_LTE60DAYS ,
	vuluniquehigh_gt30_lte60days , 
	vulhigh_gt30_lte60days ,
	VULUNIQUECRITICAL_GT30_LTE60DAYS , 
	VULCRITICAL_GT30_LTE60DAYS ,
	vulmedium , 
	vullow ,
	vuluniquemedium , 
	vuluniquelow,
    KEV_Fixed_MonthToDate, 
    KEV_Open, 
    KEV_Reopened,
	null POAMCount, 
	null Weakness_Risk_Level, 
	null Overall_Status,
    null OVERDUE_COUNT, 
    null OVERDUE_FILTER,
    null EPSS_COUNT, 
    null EPSS_FILTER
from CORE.VW_SYSTEMSUMMARY rptsummary
JOIN  (select distinct report_id,report_date from (select report_id,report_date,rank()over(order by report_date desc) as rankk from core.report_ids where Is_endOfMonth=1) a where rankk <=2) Months
ON Months.report_id=rptsummary.REPORT_ID
JOIN rpt.CRR_Component_Params params ON params.Systems=rptsummary.acronym
JOIN CORE.VW_SYSTEMS s ON s.Acronym=rptsummary.Acronym
join rpt.V_CyberRisk_System_Summary css on css."System" = s.Acronym
WHERE params.ReportName=:P_ACHRONYM

UNION ALL

Select distinct 
params.ReportName,
	s.acronym,
	null report_id,
	null report_date,
    null Assets,
    null Next_Required_CP_Test_Date,
    null component_acronym,
    null Auth_Decision,
    null Date_Auth_Memo_Expires,
    null Is_OA_Ready,
    null OA_Status,
	null AssetRiskTolerance,
	null ResidualRisk,
	null ResiliencyScore,
	null VulnRiskTolerance,
	null tot_crit_vulns,
	null tot_high_vulns,
	null TLC_Phase,
	null VULUNIQUECRITICAL_GT60DAYS, 
	null VULCRITICAL_GT60DAYS ,
	null VULUNIQUEHIGH_GT60DAYS , 
	null VULHIGH_GT60DAYS ,
	null VULUNIQUECRITICAL_GT15_LTE60DAYS , 
	null VULCRITICAL_GT15_LTE60DAYS ,
	null vuluniquehigh_gt30_lte60days , 
	null vulhigh_gt30_lte60days ,
	null VULUNIQUECRITICAL_GT30_LTE60DAYS , 
	null VULCRITICAL_GT30_LTE60DAYS ,
	null vulmedium , 
	null vullow ,
	null vuluniquemedium , 
	null vuluniquelow,
    null KEV_Fixed_MonthToDate, 
    null KEV_Open, 
    null KEV_Reopened,
    Count(P."POA&M ID") as POAMCount, 
	P."Weakness_Risk_Level", 
	P."Overall_Status", 
    null OVERDUE_COUNT, 
    null OVERDUE_FILTER,
    null EPSS_COUNT, 
    null EPSS_FILTER
from RPT.V_POAMS_MONTHENDSNAPSHOT P
inner join CORE.VW_SYSTEMS S
on P."Archer_Tracking_ID" = S.Archer_Tracking_ID
Join rpt.CRR_Component_Params params on params.systems = s.acronym where params.ReportName=:P_ACHRONYM
and "Overall_Status" not in (''Completed'', ''Pending Verification'')
group by S.Acronym, P."Weakness_Risk_Level", P."Overall_Status", params.ReportName

UNION ALL

select 
reportname,
s.Acronym, 
null Report_ID, 
null report_date,
null Assets,
null Next_Required_CP_Test_Date,
null component_acronym,
null Auth_Decision,
null Date_Auth_Memo_Expires,
null Is_OA_Ready,
null OA_Status,
null AssetRiskTolerance,
null ResidualRisk,
null ResiliencyScore,
null VulnRiskTolerance,
null tot_crit_vulns,
null tot_high_vulns,
null TLC_Phase,
null VULUNIQUECRITICAL_GT60DAYS, 
null VULCRITICAL_GT60DAYS ,
null VULUNIQUEHIGH_GT60DAYS , 
null VULHIGH_GT60DAYS ,
null VULUNIQUECRITICAL_GT15_LTE60DAYS , 
null VULCRITICAL_GT15_LTE60DAYS ,
null vuluniquehigh_gt30_lte60days , 
null vulhigh_gt30_lte60days ,
null VULUNIQUECRITICAL_GT30_LTE60DAYS , 
null VULCRITICAL_GT30_LTE60DAYS ,
null vulmedium , 
null vullow ,
null vuluniquemedium , 
null vuluniquelow,
null KEV_Fixed_MonthToDate, 
null KEV_Open, 
null KEV_Reopened,
null POAMCount, 
null Weakness_Risk_Level, 
null Overall_Status,
count(CVE) OVERDUE_COUNT, 
OVERDUE_FILTER,
null EPSS_COUNT, 
null EPSS_FILTER
from CORE.VW_SYSTEMS s
Join RPT.VW_ASSETDETAIL_ROLLING60DAYS vulcur on s.system_id = vulcur.system_id
join rpt.CRR_Component_Params params on params.systems = s.acronym
where params.ReportName=:P_ACHRONYM and OVERDUE_FILTER <> ''NULL'' and  lower(MitigationStatus) in (''open'', ''reopened'') group by s.acronym, OVERDUE_FILTER, reportname

UNION ALL

select 
reportname,
s.acronym, 
null Report_ID, 
null report_date,
null Assets,
null Next_Required_CP_Test_Date,
null component_acronym,
null Auth_Decision,
null Date_Auth_Memo_Expires,
null Is_OA_Ready,
null OA_Status,
null AssetRiskTolerance,
null ResidualRisk,
null ResiliencyScore,
null VulnRiskTolerance,
null tot_crit_vulns,
null tot_high_vulns,
null TLC_Phase,
null VULUNIQUECRITICAL_GT60DAYS, 
null VULCRITICAL_GT60DAYS ,
null VULUNIQUEHIGH_GT60DAYS , 
null VULHIGH_GT60DAYS ,
null VULUNIQUECRITICAL_GT15_LTE60DAYS , 
null VULCRITICAL_GT15_LTE60DAYS ,
null vuluniquehigh_gt30_lte60days , 
null vulhigh_gt30_lte60days ,
null VULUNIQUECRITICAL_GT30_LTE60DAYS , 
null VULCRITICAL_GT30_LTE60DAYS ,
null vulmedium , 
null vullow ,
null vuluniquemedium , 
null vuluniquelow,
null KEV_Fixed_MonthToDate, 
null KEV_Open, 
null KEV_Reopened,
null POAMCount, 
null Weakness_Risk_Level, 
null Overall_Status,
null OVERDUE_COUNT, 
null OVERDUE_FILTER,
count(CVE) EPSS_COUNT, 
EPSS_FILTER
from CORE.VW_SYSTEMS s
Join RPT.VW_ASSETDETAIL_ROLLING60DAYS vulcur on s.system_id = vulcur.system_id
join rpt.CRR_Component_Params params on params.systems = s.acronym
where params.ReportName=:P_ACHRONYM and EPSS_FILTER <> ''NULL'' and  lower(MitigationStatus) in (''open'', ''reopened'') group by s.acronym, EPSS_FILTER, reportname
order by report_id, assets
);
RETURN TABLE(res);


END;
';