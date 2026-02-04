create or replace view VW_POAMS(
	ID,
	REPORTDATE,
	ARCHER_TRACKING_ID,
	SYSTEM_ID,
	POAM_ID,
	DAYS_OPEN,
	OVERALL_STATUS,
	AUTHORIZATION_PACKAGE,
	ESTIMATED_COMPLETION_DATE,
	SCHEDULED_COMPLETION_DATE,
	ACTUAL_COMPLETION_DATE,
	CAAT_ID,
	CAAT,
	COST,
	CVE,
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
) COMMENT='Return all current POAMs.'
 as
SELECT p.ID
,r.Report_Date
,p.Archer_Tracking_ID -- 231102 was from VW_Systems
,p.SYSTEM_ID
,p.POAM_ID
,p.Days_Open
,p.Overall_Status
,p.Authorization_Package -- 231102 was from VW_Systems
,p.Estimated_Completion_Date
,p.Scheduled_Completion_Date
,p.Actual_Completion_Date
,p.CAAT_ID
,p.CAAT
,p.Cost
,p.CVE -- 240731 1641 CR918
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
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.VW_POAMHist p on p.REPORT_ID = r.REPORT_ID
/* 231102 The following was pulling all poam history when all we wanted was the most current shanpshot
ALSO, VW_POAMHist contains Archer_Tracking_ID, Authorization_Package so VW_Systems is not needed
FROM CORE.VW_POAMHist p
join CORE.REPORT_IDS csnap on csnap.REPORT_ID = p.Report_ID 
JOIN CORE.VW_Systems s on s.SYSTEM_ID = p.SYSTEM_ID
*/
;