create or replace view V_CRMP_TOTALSYSTEMS(
	COMPONENT_ACRONYM,
	TOTALSYSTEMS
) COMMENT='component acronyms for active systems'
 as
SELECT s.COMPONENT_ACRONYM as Component_Acronym
,count(1) as TotalSystems
FROM CORE.VW_Systems  s
where s.Is_OperationalSystem = 1
GROUP BY s.COMPONENT_ACRONYM
ORDER BY s.COMPONENT_ACRONYM;