create or replace view VW_CRMP_HIGHRISKSYSTEMS_WT_UP_TO_DATE_DR_PLAN(
	COMPONENT_ACRONYM,
	HIGHRISKSYSTEMSUPTODATE,
	HIGHRISKSYSTEMS,
	PCT_HIGHRISK_UPTODATE_DR_PLAN
) COMMENT='Shows total highrisk systems and percentage of uptodate dr plan by component used for CRMP.'
 as
SELECT d.Component_Acronym
,coalesce(n.HighRiskSystemsUpToDate,0) as HighRiskSystemsUpToDate
,d.HighRiskSystems
,CAST((((coalesce(n.HighRiskSystemsUpToDate,0) * 1.0) / (d.HighRiskSystems * 1.0)) * 100.0) as decimal(5,2)) as Pct_HighRisk_UpToDate_DR_Plan
FROM (SELECT s.Component_Acronym,count(1) HighRiskSystems
	FROM CORE.VW_Systems  s
	where s.Is_OperationalSystem = 1 and s.Is_HighRiskSystem = 1
	GROUP BY s.Component_Acronym) d
LEFT OUTER JOIN (SELECT s.Component_Acronym,count(1) HighRiskSystemsUpToDate
	FROM CORE.VW_Systems  s
	where s.Is_OperationalSystem = 1 and s.Is_HighRiskSystem = 1
	and DATEDIFF(month,CURRENT_TIMESTAMP,s.ContingencyExpirationDate) > 6
	GROUP BY s.Component_Acronym) n on n.Component_Acronym = d.Component_Acronym;