create or replace view V_MILESTONE_CURRSNAPSHOT(
	"ReportDate",
	ID,
	"datecreated",
	"Actual_Completion_Date",
	"Authorization_Package",
	"Changes_To_Milestone",
	"Estimated_Completion_Date",
	"Last_Updated",
	"Milestone_Description",
	"Milestone_Name",
	"Milestone_Status",
	"MilestoneID",
	POAM_ID,
	"Scheduled_Completion_Date",
	"FK_SystemID",
	CFACTS_UID
) COMMENT='Latest snapshot of Milestones related data details'
 as
SELECT 
r.REPORT_DATE as "ReportDate"
,m.ID as "ID"
, r.REPORT_DATE as "datecreated"
,m.Actual_Completion_Date as "Actual_Completion_Date"
,s.Authorization_Package as "Authorization_Package"
,m.Changes_To_Milestone as "Changes_To_Milestone"
,m.Estimated_Completion_Date as "Estimated_Completion_Date"
,m.Last_Updated as "Last_Updated"
,m.Milestone_Description as "Milestone_Description"
,m.Milestone_Name as "Milestone_Name"
,m.Milestone_Status as "Milestone_Status"
,m.MILESTONE_ID as "MilestoneID"
,m.POAM_ID as "POAM_ID"
,m.Scheduled_Completion_Date as "Scheduled_Completion_Date"
,m.SYSTEM_ID as "FK_SystemID"
,m.SYSTEM_ID as "CFACTS_UID"
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.MILESTONEHIST m on m.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = m.SYSTEM_ID
;