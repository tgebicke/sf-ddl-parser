create or replace view VW_CRMP_PCTMANAGEDASSETS(
	ACRONYM,
	LASTTOTAL,
	CURTOTAL,
	PERCENTAGE
) COMMENT='Compare percentage assets chaged by system between today and last CRR'
 as
With CurTotalAssets AS (
SELECT s.Acronym,Count(1) CurTotal FROM CORE.VW_AssetHist c 
join CORE.VW_Systems s ON c.system_id=s.SYSTEM_ID 
where c.Report_ID=(SELECT MAX(Report_ID) FROM TABLE(FN_CRM_GET_REPORT_ID(0)))
GROUP BY s.Acronym
),
LastTotalAssets AS (
SELECT s.Acronym,Count(1) lastTotal FROM CORE.VW_AssetHist c 
join CORE.VW_Systems s ON c.system_id=s.SYSTEM_ID 
where c.Report_ID=IFF((SELECT  MAX(REPORT_ID) FROM CORE.VW_REPORTSNAPSHOTS)=(SELECT MAX(Report_ID) FROM TABLE(FN_CRM_GET_REPORT_ID(1))),
(SELECT top 1 REPORT_ID FROM (SELECT top 2 REPORT_ID FROM CORE.VW_REPORTSNAPSHOTS where Is_endOfMonth=1 order by REPORT_ID desc) r order by REPORT_ID asc),
(SELECT MAX(Report_ID) FROM TABLE(FN_CRM_GET_REPORT_ID(1))))
GROUP BY s.Acronym
)
select coalesce(c.Acronym,l.Acronym) as Acronym, coalesce(l.lastTotal,0) as LastTotal,coalesce(c.CurTotal,0) as CurTotal,
cast((coalesce(c.CurTotal,0)-coalesce(l.lastTotal,0))*100.00/IFF(lastTotal=0,NULL,lastTotal) as decimal(8,2)) as Percentage from CurTotalAssets c full join LastTotalAssets l on c.Acronym=l.Acronym;