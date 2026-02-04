create or replace view V_POAMS_MONTHENDSNAPSHOT(
	ID,
	"ReportDate",
	"Archer_Tracking_ID",
	CFACTS_UID,
	"POA&M ID",
	"Days_Open",
	"Overall_Status",
	"Authorization_Package",
	"Estimated_Completion_Date",
	"Scheduled_Completion_Date",
	"Actual_Completion_Date",
	CAAT_ID,
	CAAT,
	"Cost",
	"Labor_Estimate",
	"Funding_Source",
	"POA&M_Closed_Date",
	"POA&M_Owner",
	"POA&M_Reviewer",
	"Review_Status",
	"Review_Date",
	"Review_Comments",
	"Target",
	"Submission_Status",
	"Weakness_ID",
	"Weakness_Creation_Date",
	"Weakness_Risk_Level",
	"Weakness_Severity",
	"Weakness_POC"
) COMMENT='Latest Month end snapshot of POA&Ms related data details '
 as
SELECT p.ID as "ID"
,p.REPORT_DATE as "ReportDate"
,p.ARCHER_TRACKING_ID as "Archer_Tracking_ID"
,p.SYSTEM_ID as "CFACTS_UID"
,p.POAM_ID as "POA&M ID"
,p.DAYS_OPEN as "Days_Open"
,p.OVERALL_STATUS as "Overall_Status"
,p.AUTHORIZATION_PACKAGE as "Authorization_Package"
,p.ESTIMATED_COMPLETION_DATE as "Estimated_Completion_Date"
,p.SCHEDULED_COMPLETION_DATE as "Scheduled_Completion_Date"
,p.ACTUAL_COMPLETION_DATE as "Actual_Completion_Date"
,p.CAAT_ID as "CAAT_ID"
,p.CAAT as "CAAT"
,p.COST as "Cost"
,p.LABOR_ESTIMATE as "Labor_Estimate"
,p.FUNDING_SOURCE as "Funding_Source"
,p.POAM_CLOSED_DATE as "POA&M_Closed_Date"
,p.POAM_OWNER as "POA&M_Owner"
,p.POAM_REVIEWER as "POA&M_Reviewer"
,p.REVIEW_STATUS as "Review_Status"
,p.REVIEW_DATE as "Review_Date"
,p.REVIEW_COMMENTS as "Review_Comments"
,p.TARGET as "Target"
,p.SUBMISSION_STATUS as "Submission_Status"
,p.WEAKNESS_ID as "Weakness_ID"
,p.WEAKNESS_CREATION_DATE as "Weakness_Creation_Date"
,p.WEAKNESS_RISK_LEVEL as "Weakness_Risk_Level"
,p.WEAKNESS_SEVERITY as "Weakness_Severity"
,p.WEAKNESS_POC as "Weakness_POC"
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) r
JOIN CORE.VW_POAMHIST p on p.REPORT_ID = r.REPORT_ID
;