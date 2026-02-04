create or replace view VW_CFACTS_MILESTONE(
	ACTUAL_COMP_DATE,
	CHANGES2MS,
	EST_COMP_DATE,
	LAST_UPDATED,
	MS_DESC,
	MS_ID,
	MS_NAME,
	MS_STATUS,
	POAM_ID,
	SCHED_COMP_DATE,
	SYSTEM_ID
) COMMENT='CFACTS Parent level view of POAM Milestones for a system. Child views are joined to form a coherent record'
 as 
(SELECT
REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Milestone.Actual_Completion_Date) as Actual_Comp_Date -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_Milestone.Changes_To_Milestone as Changes2MS
--,CMS_ISCM_DW.dbo.StripHTML(APP_CFACTS.SHARED.SEC_VW_Milestone.Changes_To_Milestone) as Changes2MS
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Milestone.Estimated_Completion_Date) as Est_Comp_Date -- 230801 function was in PUBLIC schema
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Milestone.Last_Updated_Date) as Last_Updated -- 230801 function was in PUBLIC schema
,APP_CFACTS.SHARED.SEC_VW_Milestone.Milestone_Description as MS_Desc
--,CMS_ISCM_DW.dbo.StripHTML(APP_CFACTS.SHARED.SEC_VW_Milestone.Milestone_Description) as MS_Desc
,APP_CFACTS.SHARED.SEC_VW_Milestone.Tracking_ID as MS_ID
,RTRIM(LTRIM(Replace(Replace(Replace(APP_CFACTS.SHARED.SEC_VW_Milestone.Milestone_Name,char(9),char(32)),'  ',' '),'"',''''))) as MS_Name
,APP_CFACTS.SHARED.SEC_VW_enum_Milestone_Status_1.Value as MS_Status
,'POA&M-'||APP_CFACTS.SHARED.SEC_VW_POAMs.POAM_ID as POAM_ID
,REF_LOOKUPS.SHARED.FN_PUB_ANY_TO_TIMESTAMP_LTZ(APP_CFACTS.SHARED.SEC_VW_Milestone.Scheduled_Completion_Date) as Sched_Comp_Date -- 230801 function was in PUBLIC schema
,s.System_ID as System_ID
from APP_CFACTS.SHARED.SEC_VW_POAMs 
inner join APP_CFACTS.SHARED.SEC_VW_Milestone_POAMs_Milestone_x_POAMs_Milestone  on APP_CFACTS.SHARED.SEC_VW_Milestone_POAMs_Milestone_x_POAMs_Milestone.POAMs_Milestone_ContentId=APP_CFACTS.SHARED.SEC_VW_POAMs.contentid
inner join APP_CFACTS.SHARED.SEC_VW_Milestone on APP_CFACTS.SHARED.SEC_VW_Milestone.ContentId=APP_CFACTS.SHARED.SEC_VW_Milestone_POAMs_Milestone_x_POAMs_Milestone.Milestone_POAMs_Milestone_ContentId

inner join APP_CFACTS.SHARED.SEC_VW_Milestone_Milestone_Status on APP_CFACTS.SHARED.SEC_VW_Milestone_Milestone_Status.ParentContentId=APP_CFACTS.SHARED.SEC_VW_Milestone.ContentId
inner join APP_CFACTS.SHARED.SEC_VW_enum_Milestone_Status_1 on APP_CFACTS.SHARED.SEC_VW_enum_Milestone_Status_1.Id=APP_CFACTS.SHARED.SEC_VW_Milestone_Milestone_Status.Value

inner JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Overall_Status on APP_CFACTS.SHARED.SEC_VW_POAMs_Overall_Status.ParentContentId = APP_CFACTS.SHARED.SEC_VW_POAMs.ContentId
inner JOIN APP_CFACTS.SHARED.SEC_VW_enum_Status_9 on APP_CFACTS.SHARED.SEC_VW_enum_Status_9.Id =  APP_CFACTS.SHARED.SEC_VW_POAMs_Overall_Status.Value

left join CORE.SYSTEMS s on s.SYSTEM_ID=APP_CFACTS.SHARED.SEC_VW_POAMs.FISMA_ID
where APP_CFACTS.SHARED.SEC_VW_enum_Status_9.Value in ('Delayed','Ongoing','Draft'))
;