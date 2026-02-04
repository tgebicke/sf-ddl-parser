create or replace view VW_TOP_10_CVE(
	FISMASEVERITY,
	CVE,
	TOTALASSETS
) COMMENT='Top 10 CVEs for Critical, High, Medium\t'
 as
SELECT t.*
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
order by t.FISMASEVERITY, t.TOTALASSETS DESC
;