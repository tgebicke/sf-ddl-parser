create or replace view VW_CRMP_SYSTEM_SUMMARY(
	REPORT_DATE,
	ACRONYM,
	AUTHORIZATION_PACKAGE,
	COMPONENT_ACRONYM,
	FINANCIAL_SYSTEM,
	FIPS_199_OVERALL_IMPACT_RATING,
	GROUP_ACRONYM,
	HVASTATUS,
	IN_CMS_CLOUD,
	IS_SECURITYHUB_ENABLED,
	MEFSTATUS,
	OATO_CATEGORY,
	PII_PHI,
	TLC_PHASE,
	VULCRITICALREMEDIATED,
	VULCRITICAL,
	VULHIGHREMEDIATED,
	VULHIGH
) COMMENT='shows every systems total high and critical vulnerability and total remediated, used for CRMP.'
 as
SELECT 
r.REPORT_DATE
,s.Acronym
,s.Authorization_Package
,s.Component_Acronym 
,s.Financial_System
,s.FIPS_199_Overall_Impact_Rating
,s.Group_Acronym 
,s.HVAStatus
,s.In_CMS_Cloud
,s.Is_SecurityHub_Enabled
,s.MEFStatus
,s.OATO_Category
,s.PII_PHI
,s.TLC_Phase
,ss.VulCriticalRemediated
,ss.VULCRITICAL
,ss.VulHighRemediated
,ss.VULHIGH
FROM CORE.VW_Systems  s
JOIN CORE.SystemSummary ss on ss.SYSTEM_ID = s.SYSTEM_ID
JOIN CORE.REPORT_IDS r on r.REPORT_ID = ss.REPORT_ID
where s.Is_OperationalSystem = 1;