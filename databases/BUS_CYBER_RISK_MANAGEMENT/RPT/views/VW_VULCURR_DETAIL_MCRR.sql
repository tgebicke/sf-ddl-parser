create or replace view VW_VULCURR_DETAIL_MCRR(
	REPORT_ID,
	SYSTEM_ID,
	SYSTEMACRONYM,
	GROUP_ACRONYM,
	GROUP_NAME,
	COMPONENT_ACRONYM,
	COMPONENT_NAME,
	CVE,
	CVSSV2BASE,
	CVSSV3BASE,
	DAYSSINCEDISCOVERY,
	DAYSSINCEDISCOVERY_FILTER,
	EXPLOITAVAILABLE,
	FIRSTSEEN,
	FISMASEVERITY,
	LASTFOUND,
	MITIGATIONSTATUS,
	IS_BOD,
	BODDUEDATE,
	DATEMITIGATED,
	EPSS,
	EPSS_FILTER,
	PERCENTILE
) COMMENT='current statistics over all vulns including EPSS and FISMAseverity metrics for CR#977'
 as
SELECT 
r.REPORT_ID
,s.SYSTEM_ID
,s.Acronym as SystemAcronym
,s.GROUP_ACRONYM
,s.GROUP_NAME
,s.COMPONENT_ACRONYM
,s.COMPONENT_NAME
,vm.cve
,v.CVSSV2BASESCORE as CVSSV2BASE 
,v.CVSSV3BASESCORE as CVSSV3Base
,v.DaysSinceDiscovery
,case 
    when v.FISMAseverity = 'Critical' and v.DAYSSINCEDISCOVERY > 15 then 'Critical >15 days'
    when v.FISMAseverity = 'High' and v.DAYSSINCEDISCOVERY > 30 then 'high >30 days'
    when v.FISMAseverity = 'Medium' and v.DAYSSINCEDISCOVERY > 90 then 'moderate > 90 days'
    when v.FISMAseverity = 'Low' and v.DAYSSINCEDISCOVERY > 365 then 'low > 365 days'
    ELSE 'NULL'
    end as DAYSSINCEDISCOVERY_FILTER 
,v.exploitAvailable
,vm.firstSeen
,v.FISMAseverity
,v.lastFound
,v.MitigationStatus
,vm.IS_KEV as Is_BOD 
,vm.BODDueDate 
,vm.datemitigated 
,epss.epss 
,case 
    when epss.epss <= 0 then '<=0%'
    when epss.epss > 0 and epss.epss <= 0.25 then '> 0% and <= 25%'
    when epss.epss > 0.25 and epss.epss <= 0.50 then '> 25% and <= 50%'
    when epss.epss > 0.50 and epss.epss <= 0.75 then '> 50% and <= 75%'
    when epss.epss > 0.75 and epss.epss <= 1 then '> 75% and <= 100%'
    ELSE 'NULL'
    End as EPSS_FILTER 
,epss.percentile 
FROM (Select max(REPORT_ID) REPORT_ID from core.report_ids where is_endofmonth = 1) r
JOIN CORE.VW_VULHIST v on v.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_VULMASTER vm on vm.DW_VUL_ID = v.dw_vul_id
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = v.SYSTEM_ID
LEFT OUTER JOIN REF_LOOKUPS.PUBLIC.SEC_MV_EPSS_SCORES epss on epss.cve_id = v.cve
where v.MitigationStatus IN ('open','reopened');