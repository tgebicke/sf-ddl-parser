create or replace view V_SYSTEMS(
	ID,
	FISMA_ID,
	"dateCreated",
	"FK_SnapshotID",
	"Acronym",
	"Archer_Tracking_ID",
	"Auth_Comments",
	"Auth_Decision",
	"Authorization_Package",
	"Business_Owner",
	CFACTS_UID,
	CIO,
	CISO,
	"Cloud_Service_Provider",
	"CommonName",
	"Component_Acronym",
	"Component_Risk_Reports_Oversight",
	"ContingencyExpirationDate",
	"CP_Test_Date",
	"CP_Test_Results",
	CRA,
	"CyberVet",
	"Date_Auth_Memo_Expires",
	"Date_Auth_Memo_Signed",
	"dateDeleted",
	"dateModified",
	DCISO,
	"Division_Acronym",
	"DivisionName",
	"E-Auth_Exp_Date",
	"E-Auth_Level",
	"E-Auth_Risk_Assessment_Date",
	"Financial_System",
	"FIPS_199_Availability_Rating",
	"FIPS_199_Confidentiality_Rating",
	"FIPS_199_Integrity_Rating",
	"FIPS_199_Overall_Impact_Rating",
	"FISMA_System",
	"Group_Acronym",
	"HVA_Score",
	"HVAStatus",
	"In_CMS_Cloud",
	"Information_System_Type",
	"Is_DataCenter",
	"Is_ExcludeFromReporting",
	"Is_HighRiskSystem",
	"Is_MarketPlace",
	"Is_OA_Ready",
	"Is_OperationalSystem",
	"Is_PhantomSystem",
	"Is_SecurityHub_Enabled",
	"ISRA_Review_Date",
	"ISRA_Status",
	"ISSO Count",
	ISSO,
	ISSOCS,
	"Last_ACT_Date",
	"Last_Pentest_Date",
	MEF,
	"MEF_Context",
	"MEFStatus",
	"OA_Status",
	"OATO_Category",
	"Package_Type",
	"PIA_Expiration_Date",
	PII_PHI,
	"Primary_ISSO",
	"Primary_Operating_Location",
	SCA,
	"SCA_Date",
	SDM,
	"ST&E_Date",
	"System_Description",
	"TLC_Phase",
	"TotalAssets",
	"TotalPOAMwithApprovedRBD",
	"VATName",
	"Next_Required_CP_Test_Date",
	"Control_Set_Version_Number_System_Provid",
	"AWS_accountIds",
	ATO_EXPIRATION_DATE,
	ATO_REVIEW_DATE,
	AUTHORIZATION_MEMO_SIGNED_DATE,
	BO_RECOMMENDATION_REVIEW_DATE,
	BO_REVIEW_DATE,
	CISO_REVIEW_DATE,
	COMPONENT_DESCRIPTION,
	COMPONENT_NAME,
	CRA_REVIEW_DATE,
	DIVISION_DESCRIPTION,
	DSPC_REVIEW_DATE,
	DSPPO_REVIEW_DATE,
	FIRST_PUBLISHED_DATE,
	GROUP_DESCRIPTION,
	GROUP_NAME,
	ISSO_REVIEW_DATE,
	ISSO_SUBMISSION_DATE,
	LAST_ACT_SCA_CAAT_PROCESSED_FILE_DATE,
	LAST_ACT_SCA_FINAL_REPORT_DATE,
	LAST_PENTEST_CAAT_PROCESSED_FILE_DATE,
	PIA_014,
	PRIMARY_OPERATING_LOCATION_ACRONYM,
	PRIMARY_OPERATING_LOCATION_ID,
	REASON_FOR_ATO_REQUEST,
	SOP_REVIEW_DATE
) WITH ROW ACCESS POLICY ACCESS_CONTROL.SECURITY.CRM_RPT_FISMA_POLICY ON (CFACTS_UID)
 COMMENT='Dimensional view for referencing the Org hierarchy data (similar to CORE.VW_SYSTEMS)'
 as
SELECT
SYSTEM_ID as "ID"
,SYSTEM_ID as FISMA_ID
,INSERT_DATE as "dateCreated"
,(SELECT TOP 1 REPORT_ID FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as "FK_SnapshotID"
,ACRONYM as "Acronym"
,ARCHER_TRACKING_ID as "Archer_Tracking_ID"
,AUTH_COMMENTS as "Auth_Comments"
,AUTH_DECISION as "Auth_Decision"
,AUTHORIZATION_PACKAGE as "Authorization_Package"
,BUSINESS_OWNER as "Business_Owner"
,SYSTEM_ID as "CFACTS_UID"
,CIO as "CIO"
,CISO as "CISO"
,CLOUD_SERVICE_PROVIDER as "Cloud_Service_Provider"
,COMMONNAME as "CommonName"
,COMPONENT_ACRONYM as "Component_Acronym"
,COMPONENT_RISK_REPORTS_OVERSIGHT as "Component_Risk_Reports_Oversight"
,CONTINGENCYEXPIRATIONDATE as "ContingencyExpirationDate"
,CP_TEST_DATE as "CP_Test_Date"
,CP_TEST_RESULTS as "CP_Test_Results"
,CRA as "CRA"
,CYBERVET as "CyberVet"
,DATE_AUTH_MEMO_EXPIRES as "Date_Auth_Memo_Expires"
,DATE_AUTH_MEMO_SIGNED as "Date_Auth_Memo_Signed"
,DATEDELETED as "dateDeleted"
,DATEMODIFIED as "dateModified"
,DCISO as "DCISO"
,DIVISION_ACRONYM as "Division_Acronym"
,DIVISION_NAME as "DivisionName"
,E_AUTH_EXP_DATE as "E-Auth_Exp_Date"
,E_AUTH_LEVEL as "E-Auth_Level"
,E_AUTH_RISK_ASSESSMENT_DATE as "E-Auth_Risk_Assessment_Date"
,FINANCIAL_SYSTEM as "Financial_System"
,FIPS_199_AVAILABILITY_RATING as "FIPS_199_Availability_Rating"
,FIPS_199_CONFIDENTIALITY_RATING as "FIPS_199_Confidentiality_Rating"
,FIPS_199_INTEGRITY_RATING as "FIPS_199_Integrity_Rating"
,FIPS_199_OVERALL_IMPACT_RATING as "FIPS_199_Overall_Impact_Rating"
,FISMA_SYSTEM as "FISMA_System"
,GROUP_ACRONYM as "Group_Acronym"
,HVA_SCORE as "HVA_Score"
,HVASTATUS as "HVAStatus"
,IN_CMS_CLOUD as "In_CMS_Cloud"
,INFORMATION_SYSTEM_TYPE as "Information_System_Type"
,IS_DATACENTER as "Is_DataCenter"
,IS_EXCLUDEFROMREPORTING as "Is_ExcludeFromReporting"
,IS_HIGHRISKSYSTEM as "Is_HighRiskSystem"
,IS_MARKETPLACE as "Is_MarketPlace"
,IS_OA_READY as "Is_OA_Ready"
,IS_OPERATIONALSYSTEM as "Is_OperationalSystem"
,IS_PHANTOMSYSTEM as "Is_PhantomSystem"
,IS_SECURITYHUB_ENABLED as "Is_SecurityHub_Enabled"
,ISRA_REVIEW_DATE as "ISRA_Review_Date"
,ISRA_STATUS as "ISRA_Status"
,ISSO_COUNT as "ISSO Count"
,ISSO as "ISSO"
,ISSOCS as "ISSOCS"
,LAST_ACT_DATE as "Last_ACT_Date"
,LAST_PENTEST_DATE as "Last_Pentest_Date"
,MEF as "MEF"
,MEF_CONTEXT as "MEF_Context"
,MEFSTATUS as "MEFStatus"
,OA_STATUS as "OA_Status"
,OATO_CATEGORY as "OATO_Category"
,PACKAGE_TYPE as "Package_Type"
,PIA_EXPIRATION_DATE as "PIA_Expiration_Date"
,PII_PHI as "PII_PHI"
,PRIMARY_ISSO as "Primary_ISSO"
,PRIMARY_OPERATING_LOCATION as "Primary_Operating_Location"
,SCA as "SCA"
,SCA_DATE as "SCA_Date"
,SDM as "SDM"
,STE_DATE as "ST&E_Date"
,SYSTEM_DESCRIPTION as "System_Description"
,TLC_PHASE as "TLC_Phase"
,TOTALASSETS as "TotalAssets"
,TOTALPOAMWITHAPPROVEDRBD as "TotalPOAMwithApprovedRBD"
,null as "VATName"
,NEXT_REQUIRED_CP_TEST_DATE as "Next_Required_CP_Test_Date"
,CONTROL_SET_VERSION_NUMBER_SYSTEM_PROVID as "Control_Set_Version_Number_System_Provid"
,AWS_ACCOUNTIDS as "AWS_accountIds"
,ATO_EXPIRATION_DATE as ATO_EXPIRATION_DATE
,ATO_REVIEW_DATE as ATO_REVIEW_DATE
,AUTHORIZATION_MEMO_SIGNED_DATE as AUTHORIZATION_MEMO_SIGNED_DATE
,BO_RECOMMENDATION_REVIEW_DATE as BO_RECOMMENDATION_REVIEW_DATE
,BO_REVIEW_DATE as BO_REVIEW_DATE
,CISO_REVIEW_DATE as CISO_REVIEW_DATE
,COMPONENT_DESCRIPTION as COMPONENT_DESCRIPTION
,COMPONENT_NAME as COMPONENT_NAME
,CRA_REVIEW_DATE as CRA_REVIEW_DATE
,DIVISION_DESCRIPTION as DIVISION_DESCRIPTION
,DSPC_REVIEW_DATE as DSPC_REVIEW_DATE
,DSPPO_REVIEW_DATE as DSPPO_REVIEW_DATE
,FIRST_PUBLISHED_DATE as FIRST_PUBLISHED_DATE
,GROUP_DESCRIPTION as GROUP_DESCRIPTION
,GROUP_NAME as GROUP_NAME
,ISSO_REVIEW_DATE as ISSO_REVIEW_DATE
,ISSO_SUBMISSION_DATE as ISSO_SUBMISSION_DATE
,LAST_ACT_SCA_CAAT_PROCESSED_FILE_DATE as LAST_ACT_SCA_CAAT_PROCESSED_FILE_DATE
,LAST_ACT_SCA_FINAL_REPORT_DATE as LAST_ACT_SCA_FINAL_REPORT_DATE
,LAST_PENTEST_CAAT_PROCESSED_FILE_DATE as LAST_PENTEST_CAAT_PROCESSED_FILE_DATE
,PIA_014 as PIA_014
,PRIMARY_OPERATING_LOCATION_ACRONYM as PRIMARY_OPERATING_LOCATION_ACRONYM
,PRIMARY_OPERATING_LOCATION_ID as PRIMARY_OPERATING_LOCATION_ID
,REASON_FOR_ATO_REQUEST as REASON_FOR_ATO_REQUEST
,SOP_REVIEW_DATE as SOP_REVIEW_DATE
FROM CORE.VW_SYSTEMS;