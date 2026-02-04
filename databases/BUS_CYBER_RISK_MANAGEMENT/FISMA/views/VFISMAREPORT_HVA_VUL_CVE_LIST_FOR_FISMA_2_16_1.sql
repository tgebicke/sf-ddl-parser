create or replace view VFISMAREPORT_HVA_VUL_CVE_LIST_FOR_FISMA_2_16_1(
	ACRONYM,
	FIPS_199_OVERALL_IMPACT_RATING,
	CVE,
	CVSSV2BASE,
	TOTAL
) COMMENT='Shows total more than 60 days open/reopen  vulnerability and has CVSSV2BASESCORE 7-9 based on system'
 as
SELECT TOP 10000
s.Acronym
,s.FIPS_199_Overall_Impact_Rating
,v.cve
,v.CVSSV2BASESCORE as CVSSV2BASE
,count(1) as Total
from table(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.VW_VULHIST v on v.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = v.SYSTEM_ID -- and s.Is_ExcludeFromReporting = 0 -- and s.Is_PhantomSystem = 0
where v.MitigationStatus IN ('open','reopened')
-- and v.Is_applicable = 1
and cast(v.CVSSV2BASESCORE as real) >= 7.0 and cast(v.CVSSV2BASESCORE as real) <= 8.9
and coalesce(s.HVAStatus,'Fake') = 'Yes'
and v.DaysSinceDiscovery > 60
-- and v.RowDisposition = 'C'
group by S.Acronym
,s.FIPS_199_Overall_Impact_Rating
,v.cve
,v.CVSSV2BASESCORE
order by S.Acronym
,s.FIPS_199_Overall_Impact_Rating
,v.cve
,v.CVSSV2BASESCORE
;