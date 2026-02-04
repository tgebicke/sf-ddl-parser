create or replace view VW_CFACTS_CAAT(
	ACT_CAAT_FILEPROCESSEDDATE,
	ASSESSMENTAUDIT_COMPANY,
	CAAT_ID,
	DATE_IDENTIFIED,
	FINDING_DESCRIPTION,
	FINDING_ID,
	FINDING_TITLE,
	RELATED_POAMS,
	SOURCE_AUDIT_TYPE_2,
	SYSTEM_ID,
	TEST_METHOD,
	TEST_OBJECTIVE,
	TEST_RESULT,
	WEAKNESS_DESCRIPTION
) COMMENT='CFACTS Parent level view of CMS Assessment and Audit Tracking for a system. Child views are joined to form a coherent record'
 as
(
WITH
cattm_1 as (SELECT APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking_Test_Method.ParentContentId as ParentContentId, listagg(APP_CFACTS.SHARED.SEC_VW_enum_Operating_Location.Value,';') AS text
	FROM APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking_Test_Method
	LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Operating_Location on APP_CFACTS.SHARED.SEC_VW_enum_Operating_Location.Id = APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking_Test_Method.Value
	Group by APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking_Test_Method.ParentContentId
)  
SELECT DISTINCT 
REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking.Created_Date) as ACT_CAAT_FileProcessedDate -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_POAMs.AssessmentAudit_Company
,'CAAT-' || cast(APP_CFACTS.SHARED.SEC_VW_POAMs.CAAT_ID as varchar) as CAAT_ID
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking.Date_Identified) as Date_Identified -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_POAMs.Finding_Description
,APP_CFACTS.SHARED.SEC_VW_POAMs.Finding_ID
,APP_CFACTS.SHARED.SEC_VW_POAMs.Finding_Title_
,'POA&M-' || cast(APP_CFACTS.SHARED.SEC_VW_POAMs.POAM_ID as varchar) as Related_POAMs
,APP_CFACTS.SHARED.SEC_VW_POAMs.Source_Audit_Type_2
,CORE.SYSTEMS.SYSTEM_ID as SYSTEM_ID
,cattm_1.text as Test_Method
,APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking.Test_Objective
,APP_CFACTS.SHARED.SEC_VW_enum_Assessment_Status.Value as Test_Result
,APP_CFACTS.SHARED.SEC_VW_POAMs.Weakness_Description
FROM APP_CFACTS.SHARED.SEC_VW_Authorization_Package
JOIN CORE.SYSTEMS on CORE.SYSTEMS.SYSTEM_ID = APP_CFACTS.SHARED.SEC_VW_Authorization_Package.IDUID
JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Authorization_Package_Related_POAMs_x_Authorization_Package_Related_POAMs on APP_CFACTS.SHARED.SEC_VW_POAMs_Authorization_Package_Related_POAMs_x_Authorization_Package_Related_POAMs.Authorization_Package_Related_POAMs_ContentId = APP_CFACTS.SHARED.SEC_VW_Authorization_Package.ContentId
JOIN APP_CFACTS.SHARED.SEC_VW_POAMs ON APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId = APP_CFACTS.SHARED.SEC_VW_POAMs_Authorization_Package_Related_POAMs_x_Authorization_Package_Related_POAMs.POAMs_Authorization_Package_Related_POAMs_ContentId
JOIN APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking on APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking.ContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.CAAT_ID
JOIN APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking_Test_Results on APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking_Test_Results.ParentContentId = APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking.ContentId
JOIN APP_CFACTS.SHARED.SEC_VW_enum_Assessment_Status on APP_CFACTS.SHARED.SEC_VW_enum_Assessment_Status.Id = APP_CFACTS.SHARED.SEC_VW_CMS_Audit_Tracking_Test_Results.Value
-- RESEARCH           
LEFT OUTER JOIN cattm_1 on cattm_1.ParentContentId = APP_CFACTS.SHARED.SEC_VW_Authorization_Package.ContentId
)
;