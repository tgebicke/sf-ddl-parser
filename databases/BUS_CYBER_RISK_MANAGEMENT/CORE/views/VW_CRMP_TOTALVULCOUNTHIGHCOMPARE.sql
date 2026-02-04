create or replace view VW_CRMP_TOTALVULCOUNTHIGHCOMPARE(
	ACRONYM,
	LASTMONTHHIGH,
	CURRENTMONTHHIGH,
	CURRENTCOMPARETOLASTMONTHHIGH
) COMMENT='Compare current and last month high vuln count by system, used for CRMP.'
 as
With CurVul AS (
SELECT System_ID,VulHigh     
FROM CORE.VW_SystemSummary where Report_ID=(SELECT MAX(Report_ID) FROM CORE.VW_REPORTSNAPSHOTS where Is_endOfMonth=1)
),
LastVul AS (
SELECT System_ID,VulHigh     
FROM CORE.VW_SystemSummary
where Report_ID=(SELECT top 1 Report_ID FROM (SELECT top 2 Report_ID FROM CORE.VW_REPORTSNAPSHOTS where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc)
)
SELECT s.Acronym,l.VulHigh as LastMonthHigh,c.VulHigh as CurrentMonthHigh,c.VulHigh-l.VulHigh as CurrentCompareToLastMonthHigh 
FROM CurVul c inner join LastVul l on c.System_ID=l.System_ID inner join CORE.VW_Systems s on s.System_ID=c.System_ID 
where l.VulHigh<>0 or c.VulHigh<>0;