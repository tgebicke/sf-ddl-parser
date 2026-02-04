create or replace view VW_MILESTONEHIST(
	REPORTDATE,
	ID,
	ACTUAL_COMPLETION_DATE,
	AUTHORIZATION_PACKAGE,
	CHANGES_TO_MILESTONE,
	ESTIMATED_COMPLETION_DATE,
	LAST_UPDATED,
	MILESTONE_DESCRIPTION,
	MILESTONE_NAME,
	MILESTONE_STATUS,
	MILESTONE_ID,
	POAM_ID,
	SCHEDULED_COMPLETION_DATE,
	SYSTEM_ID
) COMMENT='Return Milestone history ingested from CFACTS for every report_id. '
 as
SELECT 
r.REPORT_DATE as ReportDate
,m.ID
,m.Actual_Completion_Date
,s.Authorization_Package
,m.Changes_To_Milestone
,m.Estimated_Completion_Date
,m.Last_Updated
,m.Milestone_Description
,m.Milestone_Name
,m.Milestone_Status
,m.Milestone_ID
,m.POAM_ID
,m.Scheduled_Completion_Date
,s.SYSTEM_ID
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.MILESTONEHIST m on m.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = m.SYSTEM_ID
;