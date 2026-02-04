create or replace view VW_CRMP_VULAWARESCORE(
	ACRONYM,
	VULNRISKTOLERANCE
) COMMENT='Calculate VULNRISKTOLERANCE=VULAWARESCORE of every system, used for CRMP'
 as
SELECT s.Acronym
,cast(SUM(IFF(v.exploitAvailable='Yes',2*(v.DaysSinceDiscovery*cast(v.CVSSV2BASESCORE as float)*S.OATO_Category),(v.DaysSinceDiscovery*cast(v.CVSSV2BASESCORE as float)*S.OATO_Category)))/IFF(count(1)=0,1,count(1)) as decimal(8,2)) as VulnRiskTolerance
from CORE.VW_VulMaster v inner JOIN CORE.VW_Systems s on s.SYSTEM_ID=v.SYSTEM_ID
group by s.Acronym;