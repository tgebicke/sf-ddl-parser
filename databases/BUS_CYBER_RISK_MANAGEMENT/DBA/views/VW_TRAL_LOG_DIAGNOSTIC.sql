create or replace view VW_TRAL_LOG_DIAGNOSTIC(
	DATE_IDENTIFIED,
	ACRONYM,
	SYSTEM_ID,
	FISMA_SYSTEM,
	TLC_PHASE,
	SYSTEM_RISK_LEVEL,
	DESCRIPTION,
	OA_READY,
	OA_STATUS,
	SEVERITY,
	IMPACTED_CONTROLS,
	RISK_RESPONSE,
	THRESHOLDDISPLAY,
	INITIALSCORE,
	DATEMITIGATED,
	SUBSEQUENTSCORE,
	METRICNAME,
	THRESHOLD,
	LAST_PENTEST_DATE,
	DAYS_SINCE_LAST_PENTEST,
	LAST_ACT_DATE,
	DAYS_SINCE_LAST_ACT,
	VULNRISKTOLERANCE,
	RESILIENCYSCORE,
	ABS_ASSETRISKTOLERANCE,
	DATEMODIFIED,
	REPORT_ID,
	REPORT_DATE
) COMMENT='Diagnostic: Returns the log for the TRAL metrics with initial and subsequent score  '
 as
--
-- Author: Chris Rollman, IronVine
-- Date created: 4/5/22
SELECT 
tl.dateIdentified::date as Date_Identified
,s.Acronym
,s.system_id
,s.Authorization_Package as FISMA_System
,s.TLC_Phase 
,src.Description || '(' || cast(src.SYSTEMRISKCATEGORY_ID as varchar) || ')' as System_Risk_Level
,tm.TriggerDescription as Description
,coalesce(s.Is_OA_Ready=1,'Yes','No') OA_Ready
,s.OA_Status
,case tsl.RiskSeverityLevel
	when 'High' then tsl.RiskSeverityLevel || '(3)'
	when 'Moderate' then tsl.RiskSeverityLevel || '(2)'
	when 'Low' then tsl.RiskSeverityLevel || '(1)'
	Else tsl.RiskSeverityLevel
End as Severity
,tsl.ImpactedControls as Impacted_Controls
,tsl.RiskResponse as Risk_Response
,tsl.ThresholdDisplay as ThresholdDisplay
,tl.InitialScore
,tl.dateMitigated
,tl.SubsequentScore
,tm.metricname
,tsl.Threshold
,TO_CHAR(sh.last_pentest_date,'mm/dd/yyyy') as LAST_PENTEST_DATE
,DATEDIFF(d,s.Last_Pentest_Date,r.report_date) DAYS_SINCE_LAST_PENTEST
,TO_CHAR(sh.last_act_date,'mm/dd/yyyy') as LAST_ACT_DATE
,DATEDIFF(d,s.LAST_ACT_DATE,r.report_date) DAYS_SINCE_LAST_ACT
,ss.VulnRiskTolerance
,ss.ResiliencyScore
,ABS(ss.AssetRiskTolerance) as ABS_AssetRiskTolerance
,TO_CHAR(tl.DATEMODIFIED,'mm/dd/yy hh:mm') as DATEMODIFIED
,r.report_id
,TO_CHAR(r.report_date,'mm/dd/yyyy') as REPORT_DATE
FROM CORE.VW_SYSTEMS s 
JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
JOIN CORE.TRAL_Log tl on tl.System_ID = s.System_ID
JOIN CORE.TRAL_Metric tm on tm.TRAL_Metric_ID = tl.TRAL_Metric_ID
JOIN CORE.TRAL_RiskSeverityLevel tsl  on tsl.SystemRiskCategory_ID = src.SYSTEMRISKCATEGORY_ID and tsl.TRAL_Metric_ID = tl.TRAL_Metric_ID
LEFT OUTER JOIN CORE.SystemSummary ss on SS.SYSTEM_ID = s.SYSTEM_ID and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary) --ss.REPORT_ID = 497
LEFT OUTER JOIN CORE.REPORT_IDS r on r.report_id = ss.report_id
LEFT OUTER JOIN CORE.SYSTEMSHIST sh on sh.report_id = ss.report_id and sh.system_id = s.system_id
where s.TLC_Phase <> 'Retire'
--and tl.dateIdentified::date <= r.report_date::date
ORDER BY s.Acronym, tl.dateIdentified;