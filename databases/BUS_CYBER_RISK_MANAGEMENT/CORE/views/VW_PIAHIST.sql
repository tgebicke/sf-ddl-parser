create or replace view VW_PIAHIST(
	ID,
	REPORTID,
	REPORTDATE,
	ARCHER_TRACKING_ID,
	AUTHORIZATION_PACKAGE,
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
) COMMENT='Return PIA history ingested from CFACTS for every report_id. '
 as
SELECT pia.ID
,csnap.REPORT_ID as ReportID
,csnap.REPORT_DATE as ReportDate
,s.Archer_Tracking_ID
,s.Authorization_Package
,pia.Due_Date
,pia.Final_Approver
,pia.Final_Approver_Date
,pia.Final_Approver_Status
,pia.HHS_PIA_Review_Date
,pia.HHS_PIA_Status
,pia.Overall_Status
,pia.PIA_Tracking_ID
,pia.Review_Date
,pia.Review_Status
,pia.Reviewer
,pia.Submission_Date
,pia.Submission_Status
,pia.Submitter
,pia.SYSTEM_ID
FROM table(CORE.FN_CRM_GET_REPORT_ID(0)) csnap
JOIN CORE.PIAHist pia on pia.REPORT_ID = csnap.REPORT_ID
LEFT OUTER JOIN CORE.VW_Systems s on s.SYSTEM_ID = pia.SYSTEM_ID;