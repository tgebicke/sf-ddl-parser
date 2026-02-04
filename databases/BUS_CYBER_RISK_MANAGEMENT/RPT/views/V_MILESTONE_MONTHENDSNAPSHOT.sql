create or replace view V_MILESTONE_MONTHENDSNAPSHOT(
	REPORTDATE,
	ID,
	DATECREATED,
	ACTUAL_COMPLETION_DATE,
	AUTHORIZATION_PACKAGE,
	CHANGES_TO_MILESTONE,
	ESTIMATED_COMPLETION_DATE,
	LAST_UPDATED,
	MILESTONE_DESCRIPTION,
	MILESTONE_NAME,
	MILESTONE_STATUS,
	MILESTONEID,
	POAM_ID,
	SCHEDULED_COMPLETION_DATE,
	FK_SYSTEMID,
	CFACTS_UID
) COMMENT='Latest Month end snapshot of Milestones related data details'
 as
SELECT 
r.REPORT_DATE as ReportDate
,m.ID
,r.REPORT_DATE as datecreated
,m.Actual_Completion_Date
,s.Authorization_Package
,m.Changes_To_Milestone
,m.Estimated_Completion_Date
,m.Last_Updated
,m.Milestone_Description
,m.Milestone_Name
,m.Milestone_Status
,m.MILESTONE_ID as MilestoneID
,m.POAM_ID
,m.Scheduled_Completion_Date
,m.SYSTEM_ID as FK_SystemID
,m.SYSTEM_ID as CFACTS_UID
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) r
JOIN CORE.MILESTONEHIST m on m.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = m.SYSTEM_ID;