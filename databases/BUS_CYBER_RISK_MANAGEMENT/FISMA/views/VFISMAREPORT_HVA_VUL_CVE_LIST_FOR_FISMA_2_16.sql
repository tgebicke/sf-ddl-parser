create or replace view VFISMAREPORT_HVA_VUL_CVE_LIST_FOR_FISMA_2_16(
	ACRONYM,
	FIPS_199_OVERALL_IMPACT_RATING,
	CVE,
	CVSSV2BASESCORE,
	TOTAL
) COMMENT='Shows total more than 30 days open/reopen  vulnerability and has CVSSV2BASESCORE 9-10 based on system'
 as
SELECT TOP 10000
s.Acronym
,s.FIPS_199_Overall_Impact_Rating -- 231027 was sh
,v.cve
,v.CVSSV2BASESCORE
,count(1) as Total
from table(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.VW_VULHIST v on v.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = v.SYSTEM_ID
where v.MitigationStatus IN ('open','reopened')
--and v.Is_applicable = 1
and cast(v.CVSSV2BASESCORE as real) >= 9.0 and cast(v.CVSSV2BASESCORE as real) <= 10.0
and coalesce(s.HVAStatus,'Fake') = 'Yes' -- 231027 was sh
and v.DaysSinceDiscovery > 30
-- and v.RowDisposition = 'C'
group by S.Acronym
,s.FIPS_199_Overall_Impact_Rating -- 231027 was sh
,v.cve
,v.CVSSV2BASESCORE
order by S.Acronym
,s.FIPS_199_Overall_Impact_Rating -- 231027 was sh
,v.cve
,v.CVSSV2BASESCORE
;