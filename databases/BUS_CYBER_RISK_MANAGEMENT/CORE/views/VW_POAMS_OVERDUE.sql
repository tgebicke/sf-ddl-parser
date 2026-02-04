create or replace view VW_POAMS_OVERDUE(
	ID,
	REPORTDATE,
	ARCHER_TRACKING_ID,
	SYSTEM_ID,
	POAM_ID,
	DAYS_OPEN,
	DAYS_OVERDUE,
	OVERALL_STATUS,
	AUTHORIZATION_PACKAGE,
	ESTIMATED_COMPLETION_DATE,
	SCHEDULED_COMPLETION_DATE,
	ACTUAL_COMPLETION_DATE,
	CAAT_ID,
	CAAT,
	COST,
	LABOR_ESTIMATE,
	FUNDING_SOURCE,
	POAM_CLOSED_DATE,
	POAM_OWNER,
	POAM_REVIEWER,
	REVIEW_STATUS,
	REVIEW_DATE,
	REVIEW_COMMENTS,
	TARGET,
	SUBMISSION_STATUS,
	WEAKNESS_ID,
	WEAKNESS_CREATION_DATE,
	WEAKNESS_RISK_LEVEL,
	WEAKNESS_SEVERITY,
	WEAKNESS_POC
) COMMENT='Return all current POAMS that passed the estimated Completion Date'
 as
SELECT p.ID
,p.ReportDate
,p.Archer_Tracking_ID
,p.SYSTEM_ID
,p.POAM_ID
,p.Days_Open
,DATEDIFF(d,p.Estimated_Completion_Date,CURRENT_TIMESTAMP) as Days_Overdue
,p.Overall_Status
,p.Authorization_Package
,p.Estimated_Completion_Date
,p.Scheduled_Completion_Date
,p.Actual_Completion_Date
,p.CAAT_ID
,p.CAAT
,p.Cost
,p.Labor_Estimate
,p.Funding_Source
,p.POAM_Closed_Date
,p.POAM_Owner
,p.POAM_Reviewer
,p.Review_Status
,p.Review_Date
,p.Review_Comments
,p.Target
,p.Submission_Status
,p.Weakness_ID
,p.Weakness_Creation_Date
,p.Weakness_Risk_Level
,p.Weakness_Severity
,p.Weakness_POC
FROM CORE.VW_POAMS_Open p
where DATEDIFF(d,p.Estimated_Completion_Date,CURRENT_TIMESTAMP) > 0
;