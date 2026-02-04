create or replace view VW_CEDE_POAMS(
	REPORTDATE,
	"Authorization_Package",
	POAM_ID,
	"Allocated_Control",
	"POA&M Owner",
	"Overall_Status",
	"Days Open",
	"Scheduled Completion Date",
	"Actual Completion Date",
	"Audit Status",
	"Audit Review Date",
	"Business Owner (BO)",
	"CMS Assessment / Audit Tracking",
	"Count of Milestones",
	"Count of Completed Milestones",
	"# of Not Completed Milestones",
	"Component",
	"Cost",
	"Date Identified",
	"Estimated Completion Date",
	"Final POA&M Comparison Date",
	"Final POA&M Weakness Creation Date",
	"Final PO&AM Weakness ID",
	"Finding Description",
	"Finding Title",
	"FIPS 199 Overall Impact Rating",
	"Fiscal Year",
	"Funding Source",
	"POA&M Reviewer",
	"POA&M Status",
	"POA&M Status Indicator",
	"Primary Information_System Security Officer (ISSO)",
	"Recommended Corrective Action(s)",
	"RBD Overall_Status",
	"Priority",
	"Related Risk Acceptance (RBD)",
	"Review Date",
	"Review Status",
	"Review Comments",
	"Required Remediation Date",
	"Remediation Evidence",
	"Source",
	"Weakness Creation Date",
	"Weakness Description",
	"Weakness ID",
	"Weakness POC",
	"Weakness_Risk_Level",
	"Weakness Severity"
) COMMENT='Current POAMs with associated CAAT and Milestone info used for CEDE '
 as
SELECT 
csnap.REPORT_DATE as ReportDate
,sh.Authorization_Package  as "Authorization_Package"
,ph.POAM_ID
,NULL as "Allocated_Control"
,ph.POAM_Owner  as "POA&M Owner"
,ph.Overall_Status  as "Overall_Status"
,ph.Days_Open  as "Days Open"
,ph.Scheduled_Completion_Date  as "Scheduled Completion Date"
,ph.Actual_Completion_Date  as "Actual Completion Date"
,NULL as "Audit Status"
,NULL as "Audit Review Date"
,sh.Business_Owner  as "Business Owner (BO)"
,NULL as "CMS Assessment / Audit Tracking"
,coalesce(mt.Total,0)  as "Count of Milestones"
,coalesce(mc.Total,0)  as "Count of Completed Milestones"
,(coalesce(mt.Total,0) - coalesce(mc.Total,0))  as "# of Not Completed Milestones"
,s.Component_Name as "Component"
,ph.Cost  as "Cost"
,caat.Date_Identified  as "Date Identified"
,ph.Estimated_Completion_Date  as "Estimated Completion Date"
,NULL as "Final POA&M Comparison Date"
,NULL as "Final POA&M Weakness Creation Date"
,NULL as "Final PO&AM Weakness ID"
,caat.Finding_Description  as "Finding Description"
,caat.Finding_Title  as "Finding Title"
,sh.FIPS_199_Overall_Impact_Rating  as "FIPS 199 Overall Impact Rating"
,NULL as "Fiscal Year"
,ph.Funding_Source  as "Funding Source"
,ph.POAM_Reviewer  as "POA&M Reviewer"
,NULL as "POA&M Status"
,NULL as "POA&M Status Indicator"
,sh.Primary_ISSO  as "Primary Information_System Security Officer (ISSO)"
,NULL as "Recommended Corrective Action(s)"
,NULL as "RBD Overall_Status"
,NULL as "Priority"
,NULL as "Related Risk Acceptance (RBD)"
,ph.Review_Date  as "Review Date"
,ph.Review_Status  as "Review Status"
,ph.Review_Comments  as "Review Comments"
,NULL as "Required Remediation Date"
,NULL as "Remediation Evidence"
,caat.SOURCE_AUDIT_TYPE  as "Source"
,ph.Weakness_Creation_Date  as "Weakness Creation Date"
,caat.Weakness_Description  as "Weakness Description"
,ph.Weakness_ID  as "Weakness ID"
,ph.Weakness_POC  as "Weakness POC"
,ph.Weakness_Risk_Level  as "Weakness_Risk_Level"
,ph.Weakness_Severity  as "Weakness Severity"
from table(CORE.FN_CRM_GET_REPORT_ID(0)) csnap
JOIN CORE.SystemsHist sh on sh.REPORT_ID = csnap.REPORT_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = sh.SYSTEM_ID 
  
JOIN POAMHist ph on ph.REPORT_ID = csnap.REPORT_ID and ph.SYSTEM_ID = sh.SYSTEM_ID
JOIN CAATHist caat on caat.REPORT_ID = csnap.REPORT_ID 
	and caat.CAAT_ID = ph.CAAT 
	and caat.SYSTEM_ID = sh.SYSTEM_ID
LEFT OUTER JOIN (SELECT REPORT_ID,SYSTEM_ID,POAM_ID,COUNT(1) as Total 
	FROM CORE.MilestoneHist
	GROUP BY REPORT_ID,SYSTEM_ID,POAM_ID) mt on mt.REPORT_ID = csnap.REPORT_ID and mt.SYSTEM_ID = sh.SYSTEM_ID and mt.POAM_ID = ph.POAM_ID
LEFT OUTER JOIN (SELECT REPORT_ID,SYSTEM_ID,POAM_ID,COUNT(1) as Total 
	FROM CORE.MilestoneHist
	WHERE Milestone_Status IS NOT NULL and Milestone_Status = 'Completed'
	GROUP BY REPORT_ID,SYSTEM_ID,POAM_ID) mc on mt.REPORT_ID = csnap.REPORT_ID and mc.SYSTEM_ID = sh.SYSTEM_ID and mt.POAM_ID = ph.POAM_ID;