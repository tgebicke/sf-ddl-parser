create or replace view VW_CRM_PORTAL(
	REPORT_ID,
	REPORT_DATE,
	SYSTEM_ID,
	ACRONYM,
	NEXT_REQUIRED_CP_TEST_DATE,
	DATE_AUTH_MEMO_EXPIRES,
	IS_OA_READY,
	OA_STATUS,
	TLC_PHASE,
	ASSETS,
	VUL_OPEN,
	VUL_REOPENED,
	RESILIENCYSCORE,
	KEV_OPEN,
	KEV_REOPENED,
	KEV_FIXED_MONTHTODATE,
	VULNRISKTOLERANCE,
	POAM_COUNT,
	COUNT_LESS72HRS,
	COUNT_GREATER72HRS,
	TOTAL_ASSET,
	TIMELINESS_PCT,
	COUNT_SOFTWAREINSTALLED,
	VULN_OVERDUE,
	COUNT_FINDINGS,
	COUNT_PHISHING_RES_LOGIN,
	COUNT_TOTALLOGIN
) COMMENT='View reports hwam, vuln and software data for dashboard\t'
 as
select 
    rids.report_id,
    rids.report_date,
    sys.system_id,
    sys.acronym,
    sys.next_required_cp_test_date,
    sys.DATE_AUTH_MEMO_EXPIRES,
    sys.is_oa_ready,
    sys.oa_status,
    Sys.tlc_phase,
    ss.assets, 
    vulopen.vul_open, 
    vulopen.vul_reopened,
    ss.resiliencyscore,
    ss.KEV_OPEN,
    ss.KEV_REOPENED,
    ss.KEV_FIXED_MONTHTODATE,
    ss.vulnrisktolerance,
    p.POAM_COUNT,
    Count_less72Hrs,
    Count_greater72Hrs,
    total_asset,
    case when tl.Count_less72Hrs is not null then ROUND(Count_less72Hrs*100.0/tl.total_asset,1) 
    end as Timeliness_PCT,
    Count_SoftwareInstalled,
    CRITICALGT15+HIGHGT30+MODERATEGT90+LOWGT365 as VULN_OVERDUE,
    COUNT_FINDINGS,
    (select sum(piv+fido2+zscaler) from BUS_ZEROTRUST.PUBLIC.AUTHNCOUNTS 
where date(authndate) >= dateadd('month', -1, date_trunc('month', current_date)) and date(authndate) < date_trunc('month', current_date)) as COUNT_PHISHING_RES_LOGIN, --CR#1054
    (select sum(EMAIL+FIDO2+OKTAOTP+OKTAPUSH+OTP+PHONE+PIV+SMS+ZSCALER) from BUS_ZEROTRUST.PUBLIC.AUTHNCOUNTS 
where date(authndate) >= dateadd('month', -1, date_trunc('month', current_date)) and date(authndate) < date_trunc('month', current_date)) as COUNT_TOTALLOGIN --CR#1054
from (select max(report_id) report_id, max(report_date) report_date from core.report_ids where is_endofmonth = 0 UNION select max(report_id) report_id, max(report_date) report_date from core.report_ids where is_endofmonth = 1) rids
JOIN (select report_id, system_id, sum(vul_high_open +vul_critical_open+vul_medium_open+vul_low_open) vul_open, sum(vul_high_reopened + vul_critical_reopened + vul_medium_reopened + vul_low_reopened) vul_reopened from core.vw_systemsummary group by all) vulopen on vulopen.report_id = rids.report_id
left outer join (select report_id, system_id, acronym, assets, resiliencyscore, kev_open KEV_OPEN, kev_reopened kev_reopened, kev_fixed_monthtodate kev_fixed_monthtodate, vulnrisktolerance vulnrisktolerance from core.vw_systemsummary where assets <> 0) ss on vulopen.system_id = ss.system_id and ss.report_id = rids.report_id
left outer join (select report_id, system_id, count(poam_id) POAM_COUNT from core.vw_poamhist where overall_status not in ('Completed', 'Pending Verification') 
group by all) p on vulopen.system_id = p.system_id and p.report_id = rids.report_id
left outer JOIN (select distinct
report_id, system_id,
CASE when count(ah.dw_asset_id) > 1 then
count(case when DATEDIFF(day, ah.last_confirmed_time, current_date()) < 3 then 1 end)
else null
end as Count_less72Hrs,
CASE when count(ah.dw_asset_id) > 1 then
count(case when DATEDIFF(day, ah.last_confirmed_time, current_date()) > 3 then 1 end) 
else null end as Count_greater72Hrs,
sum(count(ah.dw_asset_id)) over(PARTITION BY ah.System_Id, report_id) total_asset
from core.VW_ASSETHIST ah 
group by all) tl on vulopen.system_id = tl.system_id and tl.report_id = rids.report_id
join core.vw_systems sys on sys.system_id = vulopen.system_id
left outer join (SELECT system_id, count(distinct sw.DW_ASSET_ID) Count_SoftwareInstalled from CORE.VW_ASSET_SOFTWARE sw where date(sw.dateinstalled) >= (select max(date(report_date)) from core.report_ids where is_endofmonth = 1) and date(sw.dateinstalled) <= current_date group by all) sw on sw.system_id = sys.system_id
left join (select system_id, sum(Q1) CriticalGT15,sum(Q2) as HighGT30, sum(Q3) as ModerateGT90, sum(Q4) as LowGT365 from (SELECT system_id, 
       "'OVERDUE CRITICAL'" AS Q1,
       "'OVERDUE HIGH'" AS Q2,
       "'OVERDUE MODERATE'" AS Q3, 
       "'OVERDUE LOW'" AS Q4
  FROM RPT.VW_ASSETDETAIL_ROLLING60DAYS 
    PIVOT(count(CVE) FOR OVERDUE_FILTER IN (
      'OVERDUE CRITICAL',
      'OVERDUE HIGH',
      'OVERDUE MODERATE', 
      'OVERDUE LOW')
    )where lower(MitigationStatus) in ('open', 'reopened'))  group by ALL)vulDays on ss.system_id = vulDays.system_id
 left join (select system_acronym, count(ID) COUNT_FINDINGS from APP_AWS_SECURITY_HUB.PUBLIC.SEC_VW_AWS_SECURITYHUB_ALL where PRODUCTNAME in ('config','Security Hub') and WORKFLOW_STATUS = 'NEW' group by all) sh on sh.system_acronym = ss.ACRONYM --CR#1054
;