create or replace view VW_FISMAREPORT_KEV_MEANTIME(
	KEV_MEANTIME_DAYS
) COMMENT='Remediation mean time (in days) of all KEV for Quarterly FISMA Report'
 as
--
-- 250110 Teresa; Complete Rewrite of view
-- Requirement is for one number for all KEVs mitigated in the quarter
-- Use AssetHist and VulHist to obtain state of Asset and Vul during the quarter
-- Check if KEV existed during the quarter
-- Check if KEV was active during the quarter (See KEV_CATALOG.DATEDELETED) (i.e. if mitigated after KEV was deleted dont use)
-- Dont count if reopened
-- If data is present in ASSETHIST for a given REPORT_ID then the asset is considered active at that point in time
-- If data is present in VULHIST for a given REPORT_ID then the vulnerability is considered active at that point in time
--
SELECT avg(Days_To_Mitigate) as KEV_MEANTIME_DAYS
FROM (SELECT 
-- Can be used for testing: rpt.report_Id,rpt.report_date,kev.CVE,kev.datedeleted,dw_vul_id
datediff(d,vh.FIRSTSEEN,vh.datemitigated) Days_To_Mitigate
FROM (select min(REPORT_DATE)::date as MIN_REPORT_DATE,max(REPORT_DATE)::date as MAX_REPORT_DATE
    from core.REPORT_IDS 
    where REPORT_DATE::DATE >= '2024-10-01'::DATE and REPORT_DATE::DATE <= '2024-12-31'::DATE) rptRange -- 250110 Teresa
JOIN (select REPORT_ID, REPORT_DATE::date as REPORT_DATE 
    from core.REPORT_IDS
    where IS_VIABLE = 1) rpt on rpt.REPORT_DATE::DATE >= rptRange.MIN_REPORT_DATE and rpt.REPORT_DATE::DATE <= rptRange.MAX_REPORT_DATE
JOIN core.VULHIST vh on vh.REPORT_ID = rpt.REPORT_ID
JOIN core.KEV_CATALOG kev on kev.CVE = vh.CVE
JOIN core.ASSETHIST ah on ah.REPORT_ID = rpt.REPORT_ID and ah.dw_asset_id = vh.dw_asset_id
WHERE vh.MitigationStatus = 'fixed'
and vh.datemitigated >= rptRange.MIN_REPORT_DATE and vh.datemitigated <= rptRange.MAX_REPORT_DATE
and (kev.DATEDELETED is null or vh.datemitigated < kev.DATEDELETED));