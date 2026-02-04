create or replace view V_CRMP_OATO_SYSTEMS(
	"Acronym",
	FISMA_ID,
	"OA Ready",
	"OA_Status",
	"ResidualRisk",
	"Asset Risk Tolerance",
	"TotalAssets",
	"OATO_Category",
	"HVAStatus",
	"MEFStatus",
	"FIPS_199_Overall_Impact_Rating",
	PII_PHI,
	"Financial_System",
	"Component",
	"DevSecOPS / CSM",
	"Group_Acronym",
	"In_CMS_Cloud",
	"Last_ACT_Date",
	"Last_ACT_SCA_Final_Report_Date",
	"Last_Pentest_Date",
	"Is_SecurityHub_Enabled",
	"System",
	"TLC_Phase",
	"Vuln Risk Tolerance",
	"Resiliency Score",
	"Primary_Operating_Location",
	"Is_MarketPlace"
) WITH ROW ACCESS POLICY ACCESS_CONTROL.SECURITY.CRM_RPT_FISMA_POLICY ON (FISMA_ID)
 COMMENT='Contains System level Ongoing \"Authorization information\" and related metrics like Asset Risk Tolerance, Vuln Risk tolernace, System resiliency etc'
 as
SELECT 
s.Acronym as "Acronym"
,s.system_id FISMA_ID
,IFF(s.Is_OA_Ready=1,'Yes','No') as "OA Ready"
,s.OA_Status as "OA_Status"
,s.TotalPOAMwithApprovedRBD as "ResidualRisk"
,ss.AssetRiskTolerance as "Asset Risk Tolerance"
,ss.Assets as "TotalAssets"
,s.OATO_Category as "OATO_Category"
,s.HVAStatus as "HVAStatus"
,s.MEFStatus as "MEFStatus"
,s.FIPS_199_Overall_Impact_Rating as "FIPS_199_Overall_Impact_Rating"
,s.PII_PHI as "PII_PHI"
,s.Financial_System as "Financial_System"
,s.Component_Acronym as "Component"
,'TBD' as "DevSecOPS / CSM"
,s.Group_Acronym as "Group_Acronym"
,coalesce(s.In_CMS_Cloud,'No') as "In_CMS_Cloud"
,s.Last_ACT_Date as "Last_ACT_Date"
,s.Last_ACT_SCA_Final_Report_Date  as "Last_ACT_SCA_Final_Report_Date"
,s.Last_Pentest_Date as "Last_Pentest_Date"
,IFF(s.Is_SecurityHub_Enabled=1,'Yes','No') as "Is_SecurityHub_Enabled"
,s.AUTHORIZATION_PACKAGE as "System"
,s.TLC_Phase as "TLC_Phase"
,ss.VulnRiskTolerance  as "Vuln Risk Tolerance"
,ss.ResiliencyScore as "Resiliency Score"
,s.PRIMARY_OPERATING_LOCATION as "Primary_Operating_Location"
,s.IS_MARKETPLACE as "Is_MarketPlace" -- 231108 1545 added
FROM CORE.VW_Systems  s
-- 240222 CR840 chg from table SYSTEMSUMMARY to view VW_SYSTEMSUMMARY
JOIN CORE.VW_SYSTEMSUMMARY ss on ss.SYSTEM_ID = s.SYSTEM_ID and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.VW_SYSTEMSUMMARY)
where s.Is_OperationalSystem = 1;