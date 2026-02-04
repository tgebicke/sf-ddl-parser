create or replace view VW_CRMP_TOTALVULCOUNTCRITICALCOMPARE(
	ACRONYM,
	LASTMONTHCRITICAL,
	CURRENTMONTHCRITICAL,
	CURRENTCOMPARETOLASTMONTHCRITICAL
) COMMENT='Compare current and last month critical vuln count by system, used for CRMP.'
 as
With CurVul AS (
SELECT System_ID,VulCritical     
FROM CORE.VW_SystemSummary where Report_ID=(SELECT MAX(Report_ID) FROM CORE.REPORT_IDS where Is_endOfMonth=1)
),
LastVul AS (
SELECT System_ID,VulCritical     
FROM CORE.VW_SystemSummary
where Report_ID=(SELECT top 1 Report_ID FROM (SELECT top 2 Report_ID FROM CORE.REPORT_IDS where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc)
)
SELECT s.Acronym,l.VulCritical as LastMonthCritical,c.VulCritical as CurrentMonthCritical,c.VulCritical-l.VulCritical as CurrentCompareToLastMonthCritical 
FROM CurVul c inner join LastVul l on c.System_ID=l.System_ID inner join CORE.VW_Systems s on s.System_ID=c.System_ID 
where l.VulCritical<>0 or c.VulCritical<>0;