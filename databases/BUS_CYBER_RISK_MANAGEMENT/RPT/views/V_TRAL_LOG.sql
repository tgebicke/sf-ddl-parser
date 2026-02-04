create or replace view V_TRAL_LOG(
	DATE_IDENTIFIED,
	ACRONYM,
	FISMA_SYSTEM,
	TLC_PHASE,
	SYSTEM_RISK_LEVEL,
	DESCRIPTION,
	OA_READY,
	OA_STATUS,
	SEVERITY,
	IMPACTED_CONTROLS,
	RISK_RESPONSE,
	THRESHOLD,
	INITIALSCORE,
	DATEMITIGATED,
	SUBSEQUENTSCORE
) COMMENT='Trigger Accountability Log related information used in conjunction with Ongoing Auth related metrics'
 as
--
-- Author: Chris Rollman, IronVine
-- Date created: 4/5/22
SELECT 
tl.dateIdentified::date as Date_Identified
,s.Acronym
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
,tsl.ThresholdDisplay as Threshold
,tl.InitialScore
,tl.dateMitigated
,tl.SubsequentScore
FROM CORE.VW_SYSTEMS s 
JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
JOIN CORE.TRAL_Log tl on tl.System_ID = s.System_ID
JOIN CORE.TRAL_Metric tm on tm.TRAL_Metric_ID = tl.TRAL_Metric_ID
JOIN CORE.TRAL_RiskSeverityLevel tsl  on tsl.SystemRiskCategory_ID = src.SYSTEMRISKCATEGORY_ID and tsl.TRAL_Metric_ID = tl.TRAL_Metric_ID
where s.TLC_Phase <> 'Retire'
ORDER BY s.Acronym, tl.dateIdentified;