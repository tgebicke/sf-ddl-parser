create or replace view VW_TOP_10_CVE(
	FISMASEVERITY,
	CVE,
	EPSS,
	TOTALASSETS
) COMMENT='Top 10 CVEs for Critical, High, Medium\t'
 as
SELECT t.FISMASEVERITY,t.CVE,epss.epss,t.TOTALASSETS
FROM (
(select top 10 FISMASEVERITY,cve,count(1) TOTALASSETS 
from CORE.VW_VULMASTER where fismaseverity = 'Critical' and MITIGATIONSTATUS <> 'fixed' group by FISMASEVERITY,cve order by count(1) DESC)
UNION ALL
(select top 10 FISMASEVERITY,cve,count(1) TOTALASSETS 
from CORE.VW_VULMASTER where fismaseverity = 'High' and MITIGATIONSTATUS <> 'fixed' group by FISMASEVERITY,cve order by count(1) DESC)
UNION ALL
(select top 10 FISMASEVERITY,cve,count(1) TOTALASSETS 
from CORE.VW_VULMASTER where fismaseverity = 'Medium' and MITIGATIONSTATUS <> 'fixed' group by FISMASEVERITY,cve order by count(1) DESC)
) t
LEFT OUTER JOIN REF_LOOKUPS.PUBLIC.SEC_MV_EPSS_SCORES epss on epss.cve_id = t.cve
order by t.FISMASEVERITY, t.TOTALASSETS DESC
;