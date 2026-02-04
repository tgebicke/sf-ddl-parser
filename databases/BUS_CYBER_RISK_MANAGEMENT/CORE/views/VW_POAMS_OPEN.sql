create or replace view VW_POAMS_OPEN(
	ID,
	REPORTDATE,
	ARCHER_TRACKING_ID,
	SYSTEM_ID,
	POAM_ID,
	DAYS_OPEN,
	COMPUTEDDAYSOPEN_TESTING,
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
) COMMENT='Return all current not completed or closed POAMS'
 as
SELECT p.ID
,p.ReportDate
,p.Archer_Tracking_ID
,p.SYSTEM_ID
,p.POAM_ID
,p.Days_Open
,DATEDIFF(d,Weakness_Creation_Date,CURRENT_TIMESTAMP) as ComputedDaysOpen_TESTING
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
FROM CORE.VW_POAMS p
where p.Overall_Status NOT IN -- 250123 CR1071
(
'Closed for System Retired'
,'Completed'
,'Pending Verification'
,'Risk Accepted'
);