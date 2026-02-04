create or replace view VW_CRMP_OATO_SYSTEMS_NEW(
	ACRONYM,
	OA_READY,
	OA_STATUS,
	RESIDUALRISK,
	"Asset Risk Tolerance",
	TOTALASSETS,
	OATO_CATEGORY,
	HVASTATUS,
	MEFSTATUS,
	FIPS_199_OVERALL_IMPACT_RATING,
	PII_PHI,
	FINANCIAL_SYSTEM,
	COMPONENT,
	"DevSecOPS / CSM",
	GROUP_ACRONYM,
	IN_CMS_CLOUD,
	LAST_ACT_DATE,
	LAST_ACT_SCA_FINAL_REPORT_DATE,
	LAST_PENTEST_DATE,
	IS_SECURITYHUB_ENABLED,
	SYSTEM,
	TLC_PHASE,
	"Vuln Risk Tolerance",
	"Resiliency Score"
) COMMENT='Shows detail of OATO systems used for CRMP'
 as
SELECT 
s.Acronym
,IFF(s.Is_OA_Ready=1,'Yes','No') as OA_Ready
,s.OA_Status
,s.TotalPOAMwithApprovedRBD ResidualRisk
,ss.AssetRiskTolerance as "Asset Risk Tolerance" 
,ss.Assets as TotalAssets
,s.OATO_Category
,s.HVAStatus
,s.MEFStatus
,s.FIPS_199_Overall_Impact_Rating
,s.PII_PHI
,s.Financial_System
,s.Component_Acronym as Component
,'TBD' as "DevSecOPS / CSM"
,s.Group_Acronym
,coalesce(s.In_CMS_Cloud,'No') as In_CMS_Cloud
,s.Last_ACT_Date
,s.Last_ACT_SCA_Final_Report_Date -- 211019 1903
,s.Last_Pentest_Date
,IFF(s.Is_SecurityHub_Enabled=1,'Yes','No') Is_SecurityHub_Enabled
,s.Authorization_Package System
,s.TLC_Phase
,ss.VulnRiskTolerance as "Vuln Risk Tolerance" 
,ss.ResiliencyScore as "Resiliency Score" 
FROM CORE.VW_Systems  s
JOIN CORE.SystemSummary ss on ss.SYSTEM_ID = s.SYSTEM_ID and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary)
where s.Is_OperationalSystem = 1;