create or replace view VW_CFACTS_PIA(
	DUE_DATE,
	FINAL_APPROVER,
	FINAL_APPROVER_DATE,
	FINAL_APPROVER_STATUS,
	HHS_PIA_REVIEW_DATE,
	HHS_PIA_STATUS,
	OVERALL_STATUS,
	PIA_TRACKING_ID,
	REVIEW_DATE,
	REVIEW_STATUS,
	REVIEWER,
	SUBMISSION_DATE,
	SUBMISSION_STATUS,
	SUBMITTER,
	SYSTEM_ID
) COMMENT='Detail  PIA ( Assessment and Audit Tracking) from CFACTS.'
 as
(
WITH
subitter_1 as
	(select ParentContentId as ParentContentId, listagg(substring(DisplayName,charindex(',',DisplayName)+2,len(DisplayName))||' '||substring(DisplayName,1,charindex(',',DisplayName)-1),';') as DisplayName
from APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Submitter 
	group by ParentContentId) ,
revr_1 as
	(select ParentContentId as ParentContentId, listagg(substring(DisplayName,charindex(',',DisplayName)+2,len(DisplayName))||' '||substring(DisplayName,1,charindex(',',DisplayName)-1),';') as DisplayName
	from APP_CFACTS.SHARED.SEC_VW_PRIVACY_IMPACT_ASSESSMENT_PIA_NEW_REVIEWER 
	group by ParentContentId
) 
SELECT
REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.Due_Date) as Due_Date -- 230801 function was in PUBLIC schema
-- Research why FinalApprover is always null
,substring(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver__New.DisplayName,charindex(',',APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver__New.DisplayName)+2,len(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver__New.DisplayName)) || ' ' || substring(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver__New.DisplayName,1,charindex(',',APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver__New.DisplayName)-1) as Final_Approver
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.Final_Approver_Date) as Final_Approver_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_enum_Final_Approver_Status.Value as Final_Approver_Status
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.HHS_PIA_Status_Date_) as HHS_PIA_Review_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_enum_HSDW_.Value as HHS_PIA_Status
,APP_CFACTS.SHARED.SEC_VW_enum_Overall_Status.Value as Overall_Status
,APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId as PIA_Tracking_ID
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.Review_Date) as Review_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_enum_Review_Status_1.Value as Review_Status
,revr_1.DisplayName as Reviewer
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.Submit_Date) as Submission_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_enum_Risk_Submission_Status.Value as Submission_Status
,subitter_1.DisplayName as submitter
,CORE.SYSTEMS.System_ID as SYSTEM_ID
from APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE
inner join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Privacy_Impact_Assessment_PIA_NEW_Author_x_Privacy_Impact_Assessment_PIA_NEW_Authorization_Package
    on APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE.ContentId=APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Privacy_Impact_Assessment_PIA_NEW_Author_x_Privacy_Impact_Assessment_PIA_NEW_Authorization_Package.Authorization_Package_Privacy_Impact_Assessment_PIA_NEW_Author_ContentId
inner join APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW 
    on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId=APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Privacy_Impact_Assessment_PIA_NEW_Author_x_Privacy_Impact_Assessment_PIA_NEW_Authorization_Package.Privacy_Impact_Assessment_PIA_NEW_Authorization_Package_ContentId

left join CORE.SYSTEMS on CORE.SYSTEMS.SYSTEM_ID = APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE.IDUID

left join APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver__New  on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver__New.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId
left join APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver_Status  on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver_Status.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId
left join APP_CFACTS.SHARED.SEC_VW_enum_Final_Approver_Status  on APP_CFACTS.SHARED.SEC_VW_enum_Final_Approver_Status.ID=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Final_Approver_Status.value

left join APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_HSDW_  on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_HSDW_.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId
left join APP_CFACTS.SHARED.SEC_VW_enum_HSDW_  on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_HSDW_.Value=APP_CFACTS.SHARED.SEC_VW_enum_HSDW_.Id

left join APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Overall_Status  on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Overall_Status.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId
left join APP_CFACTS.SHARED.SEC_VW_enum_Overall_Status on APP_CFACTS.SHARED.SEC_VW_enum_Overall_Status.Id=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Overall_Status.Value

left join APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Review_Status_1 on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Review_Status_1.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId
left join APP_CFACTS.SHARED.SEC_VW_enum_Review_Status_1 on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Review_Status_1.Value=APP_CFACTS.SHARED.SEC_VW_enum_Review_Status_1.Id

left join APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Submission_Status on APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Submission_Status.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId 
left join APP_CFACTS.SHARED.SEC_VW_enum_Risk_Submission_Status on APP_CFACTS.SHARED.SEC_VW_enum_Risk_Submission_Status.Id= APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW_Submission_Status.Value
left join subitter_1 on subitter_1.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId -- RESEARCH, WAS INNER JOIN
left join revr_1 on revr_1.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Privacy_Impact_Assessment_PIA_NEW.ContentId) -- RESEARCH, WAS INNER JOIN
;