create or replace view VW_CFACTS_POAM(
	ACTUAL_COMPLETION_DATE,
	ACTUAL_LABOR_COST,
	CAAT,
	CAAT_ID,
	DAYS_OPEN,
	ESTIMATED_COMPLETION_DATE,
	FINDING_ID,
	FUNDING_SOURCE,
	LABOR_ESTIMATE,
	OVERALL_STATUS,
	POAM_CLOSED_DATE,
	POAM_ID,
	POAM_OWNER,
	POAM_REVIEWER,
	REVIEW_COMMENTS,
	REVIEW_DATE,
	REVIEW_STATUS,
	SCHEDULED_COMPLETION_DATE,
	SOURCE_AUDIT_TYPE_2,
	SUBMISSION_STATUS,
	SYSTEM_ID,
	TARGET,
	WEAKNESS_CREATION_DATE,
	WEAKNESS_ID,
	WEAKNESS_POC,
	WEAKNESS_RISK_LEVEL,
	WEAKNESS_SEVERITY
) COMMENT='CFACTS Parent level view of POAMs for a system. Child views are joined to form a coherent record'
 as
(
with 
poamOwner_1 as
	(select ParentContentId as ParentContentId, listagg(DisplayName, ';') as displayname
	from APP_CFACTS.SHARED.SEC_VW_POAMs_POAM_Owner_1 
	group by ParentContentId),
poamReviewer_1 as
	(select ParentContentId as ParentContentId, listagg(DisplayName,';') as DisplayName
	FROM APP_CFACTS.SHARED.SEC_VW_POAMs_POAM_Reviewer 
	Group by ParentContentId),
weaknessPOC_1 as
	(select ParentContentId as ParentContentId, listagg(DisplayName,';') as DisplayName
	FROM APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_POC_Role 
	group by ParentContentId
)
SELECT
REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_POAMs.Actual_Completion_Date) as Actual_Completion_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_POAMs.Actual_Labor_Cost
,'CAAT-' || cast(APP_CFACTS.SHARED.SEC_VW_POAMs.CAAT_ID as varchar) CAAT   -- DONT NEED THIS
,APP_CFACTS.SHARED.SEC_VW_POAMs.CAAT_ID
,APP_CFACTS.SHARED.SEC_VW_POAMs.Days_Open
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_POAMs.Scheduled_Completion_Date) as Estimated_Completion_Date -- Reversed in CFACTS_DPS; -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_POAMs.FINDING_ID
,APP_CFACTS.SHARED.SEC_VW_enum_Funding_Source.Value Funding_Source
,APP_CFACTS.SHARED.SEC_VW_POAMs.Labor_Estimate
,APP_CFACTS.SHARED.SEC_VW_enum_Status_9.value Overall_Status
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_POAMs.POAM_Closed_Date) as POAM_Closed_Date -- 230801 function was in PUBLIC schema
,'POA&M-' || cast(APP_CFACTS.SHARED.SEC_VW_POAMs.POAM_ID as varchar) as POAM_ID
,poamOwner_1.displayname as POAM_Owner
,poamReviewer_1.DisplayName as POAM_Reviewer
,APP_CFACTS.SHARED.SEC_VW_POAMs.Review_Comments Review_Comments
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_POAMs.Review_Date) as Review_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_enum_Risk_Review_Status.Value Review_Status
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_POAMs.Estimated_Completion_Date) as Scheduled_Completion_Date -- Reversed in CFACTS_DPS; -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_POAMs.SOURCE_AUDIT_TYPE_2
,APP_CFACTS.SHARED.SEC_VW_enum_Risk_Submission_Status.Value Submission_Status
,CORE.SYSTEMS.SYSTEM_ID as SYSTEM_ID
,'Allocated Control: ' || APP_CFACTS.SHARED.SEC_VW_POAMs.Control_Number_1 Target
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_POAMs.First_Published_Date) as Weakness_Creation_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_POAMs.Weakness_ID_Number Weakness_ID
,weaknessPOC_1.DisplayName as Weakness_POC
,APP_CFACTS.SHARED.SEC_VW_enum_Risk_Level_1.Value Weakness_Risk_Level
,APP_CFACTS.SHARED.SEC_VW_enum_Weakness_Severity.Value Weakness_Severity
FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE 
LEFT OUTER JOIN CORE.SYSTEMS on CORE.SYSTEMS.SYSTEM_ID = APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE.IDUID
INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Authorization_Package_x_Authorization_Package_POAMs ON APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE.ContentId=APP_CFACTS.SHARED.SEC_VW_POAMs_Authorization_Package_x_Authorization_Package_POAMs.Authorization_Package_POAMs_ContentId
INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs ON APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId=APP_CFACTS.SHARED.SEC_VW_POAMs_Authorization_Package_x_Authorization_Package_POAMs.POAMs_Authorization_Package_ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Risk_Level_1 on APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Risk_Level_1.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Risk_Level_1 on APP_CFACTS.SHARED.SEC_VW_enum_Risk_Level_1.ID = APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Risk_Level_1.Value
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Overall_Status ON APP_CFACTS.SHARED.SEC_VW_POAMs_Overall_Status.ParentContentId=APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Status_9  ON APP_CFACTS.SHARED.SEC_VW_enum_Status_9.Id=APP_CFACTS.SHARED.SEC_VW_POAMs_Overall_Status.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Review_Status on APP_CFACTS.SHARED.SEC_VW_POAMs_Review_Status.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Risk_Review_Status  on APP_CFACTS.SHARED.SEC_VW_enum_Risk_Review_Status.Id=APP_CFACTS.SHARED.SEC_VW_POAMs_Review_Status.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Submission_Status on APP_CFACTS.SHARED.SEC_VW_POAMs_Submission_Status.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Risk_Submission_Status  on APP_CFACTS.SHARED.SEC_VW_enum_Risk_Submission_Status.Id = APP_CFACTS.SHARED.SEC_VW_POAMs_Submission_Status.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Severity on APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Severity.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Weakness_Severity  on APP_CFACTS.SHARED.SEC_VW_enum_Weakness_Severity.Id = APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Severity.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Funding_Source  on APP_CFACTS.SHARED.SEC_VW_POAMs_Funding_Source.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Funding_Source  on APP_CFACTS.SHARED.SEC_VW_enum_Funding_Source.Id = APP_CFACTS.SHARED.SEC_VW_POAMs_Funding_Source.Value
LEFT join poamOwner_1 on poamOwner_1.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId 
LEFT join poamReviewer_1 on poamReviewer_1.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId 
LEFT join weaknessPOC_1  on weaknessPOC_1.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
);