create or replace view V_CRMP_TOTALHVASYSTEMS(
	COMPONENT_ACRONYM,
	TOTALHVASYSTEMS
) COMMENT='component acronyms for HVA systems'
 as
SELECT  s.Component_Acronym
,count(1) as TotalHVASystems
FROM CORE.VW_CRMP_OperationalSystems s
WHERE s.HVAStatus IS NOT NULL and s.HVAStatus = 'Yes'
GROUP BY s.Component_Acronym
ORDER BY s.Component_Acronym;