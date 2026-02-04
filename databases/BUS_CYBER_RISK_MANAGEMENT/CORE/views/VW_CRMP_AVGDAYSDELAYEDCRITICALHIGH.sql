create or replace view VW_CRMP_AVGDAYSDELAYEDCRITICALHIGH(
	ACRONYM,
	TOTALDELAYEDPOAMS,
	AVGDELAYCRITICAL,
	AVGDELAYHIGH
) COMMENT='Shows total critical and high POAM with delayed status used for CRMP'
 as
with CriticalPoam AS (
SELECT 
s.Acronym
,COUNT(1) TotalDelayedPOAMs
,SUM(DATEDIFF(DAY,p.Scheduled_Completion_Date,GETDATE()))/COUNT(1) AS AvgDelayInDays
FROM CORE.VW_POAMHist p 
JOIN CORE.VW_Systems s ON p.System_ID=s.System_ID
WHERE p.Overall_Status='Delayed' and p.Weakness_Risk_Level ='Critical'
and p.REPORT_ID=(SELECT REPORT_ID FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)))
GROUP BY s.Acronym 
),
HighPoam AS (
SELECT 
s.Acronym
,COUNT(1) TotalDelayedPOAMs
,SUM(DATEDIFF(DAY,p.Scheduled_Completion_Date,GETDATE()))/COUNT(1) AS AvgDelayInDays
FROM CORE.VW_POAMHist p
JOIN CORE.VW_Systems s ON p.System_ID=s.System_ID
WHERE p.Overall_Status='Delayed' and p.Weakness_Risk_Level ='High'
and p.REPORT_ID=(SELECT REPORT_ID FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)))
GROUP BY s.Acronym
)
SELECT coalesce(c.Acronym,h.Acronym) AS Acronym, coalesce(c.TotalDelayedPOAMs,h.TotalDelayedPOAMs) AS TotalDelayedPOAMs 
,coalesce(c.AvgDelayInDays,0) AS AvgDelayCritical,coalesce(h.AvgDelayInDays,0) AS AvgDelayHigh
 FROM CriticalPoam c full join HighPoam h ON c.Acronym=h.Acronym;