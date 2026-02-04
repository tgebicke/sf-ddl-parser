create or replace view VW_TRAL_RISKSEVERITYLEVEL(
	SYSTEMRISKCATEGORY,
	DESCRIPTION,
	METRICID,
	METRICNAME,
	TRIGGERDESCRIPTION,
	THRESHOLDDISPLAY,
	THRESHOLD,
	POTENTIALTHREATSOURCES,
	IMPACT,
	LIKELIHOODINITIATION,
	LIKELIHOODADVERSEIMPACT,
	OVERALLLIKELIHOOD,
	RISKSEVERITYLEVEL,
	IMPACTEDCONTROLS,
	RISKRESPONSE
) COMMENT='Returns risk severity, risk category, likelyhood and other TRAL metrics information. '
 as
SELECT src.SYSTEMRISKCATEGORY_ID as SystemRiskCategory
,src.Description
,tm.TRAL_METRIC_ID as MetricID
,tm.MetricName
,tm.TriggerDescription
,tsl.ThresholdDisplay
,tsl.Threshold
,tm.PotentialThreatSources
,tsl.Impact
,tsl.LikelihoodInitiation
,tsl.LikelihoodAdverseImpact
,tsl.OverallLikelihood
,tsl.RiskSeverityLevel
,tsl.ImpactedControls
,tsl.RiskResponse
FROM CORE.SystemRiskCategory src 
JOIN CORE.TRAL_RiskSeverityLevel tsl on tsl.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
JOIN CORE.TRAL_Metric tm on tm.TRAL_METRIC_ID = tsl.TRAL_METRIC_ID
ORDER BY src.SYSTEMRISKCATEGORY_ID,tsl.RiskSeverityLevel,tm.TRAL_METRIC_ID;