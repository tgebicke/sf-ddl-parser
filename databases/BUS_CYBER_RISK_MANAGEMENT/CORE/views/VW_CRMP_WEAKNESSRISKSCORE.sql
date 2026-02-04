create or replace view VW_CRMP_WEAKNESSRISKSCORE(
	ACRONYM,
	RESILIENCYSCORE
) COMMENT='Calculate RESILIENCYSCORE=WEAKNESSRISKSCORE of every system, used for CRMP'
 as 
SELECT 
s.Acronym
,SUM(IFF(p.Weakness_Risk_Level='Critical',45,IFF(p.Weakness_Risk_Level='High',30,IFF(p.Weakness_Risk_Level='Moderate',15,IFF(p.Weakness_Risk_Level='Low',10,1))))) ResiliencyScore
FROM table(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.VW_POAMHist p on p.REPORT_ID = r.REPORT_ID
INNER JOIN CORE.VW_Systems s ON p.SYSTEM_ID=s.SYSTEM_ID
WHERE p.Overall_Status in ('Delayed', 'Ongoing', 'Draft')
GROUP BY s.Acronym;