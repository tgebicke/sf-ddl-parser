create or replace view VW_CEDE_PRIVACY_IMPACT_ASSESSMENT(
	REPORTDATE,
	"Authorization_Package",
	"Tracking ID",
	"Administrators Explanation",
	"ATO Expiration Date",
	"Authorization_Package: ISSO - ISSOCS",
	"CMS Final Approver",
	"CMS Final Approver Date",
	"CMS Final Approver Review Status",
	"CMS SOP",
	"Component",
	"Contractors Explanation",
	"CRA Review Status",
	"CRA Reviewer",
	"Created By",
	"Default Record Permissions",
	"Developers Explanation",
	"Does the PIA have an Expiration Date?",
	"Form Date",
	"Helper PIA-014",
	"Helper XLC Phase = Disposition for Notifications",
	"HHS PIA Review Date",
	"HHS PIA Review Status",
	"HHS PIA Reviewer",
	"HHS PIA Tracker Comments",
	"Inherited Record Permissions",
	"Is this a PIA Renewal?",
	"ISSO Submitter",
	"Last Updated",
	"Original - PIA-014",
	"Other - Collects PII?",
	"Other Federal Agency/Agencies Explanation",
	"Others Explanation",
	"Overall_Status",
	"Persistent Cookies - Collects PII?",
	"PIA Expiration Date",
	"PIA-001",
	"PIA-002",
	"PIA-002a",
	"PIA-003",
	"PIA-003a",
	"PIA-003b",
	"PIA-004",
	"PIA-005",
	"PIA-006a",
	"PIA-006b",
	"PIA-006c",
	"PIA-006d",
	"PIA-006e",
	"PIA-007",
	"PIA-008",
	"PIA-008a",
	"PIA-008b",
	"PIA-009",
	"PIA-010",
	"PIA-011",
	"PIA-012",
	"PIA-013",
	"PIA-014",
	"PIA-015",
	"PIA-016",
	"PIA-017",
	"PIA-018",
	"PIA-019",
	"PIA-020",
	"PIA-020a",
	"PIA-021",
	"PIA-022",
	"PIA-022a",
	"PIA-022ai",
	"PIA-023",
	"PIA-023a",
	"PIA-023ii",
	"PIA-023iii",
	"PIA-024",
	"PIA-024a",
	"PIA-024b",
	"PIA-024c",
	"PIA-025",
	"PIA-026",
	"PIA-027",
	"PIA-028",
	"PIA-029",
	"PIA-030",
	"PIA-031",
	"PIA-032",
	"PIA-033",
	"PIA-034",
	"PIA-035",
	"PIA-036",
	"PIA-037",
	"PIA-038",
	"PIA-039",
	"PIA-040",
	"PIA-040a",
	"PIA-041",
	"PIA-041a",
	"PIA-042",
	"PIA-042a",
	"PIA-043",
	"PIA-043a",
	"PIARev-001",
	"PIARev-002",
	"PIARev-003",
	"PIARev-004",
	"PIARev-005",
	"PIARev-006",
	"PIARev-007",
	"PIARev-008",
	"PIARev-009",
	"PIARev-010",
	"PIARev-011",
	"PIARev-012",
	"Privacy Threshold Analysis (PTA)",
	"Private Sector Explanation",
	"Recent Date of Return to CMS by Department",
	"Recent Date of Submittal by CMS",
	"Record Status",
	"Require HHS PIA Status Field Trigger",
	"Review Date",
	"Session Cookies - Collects PII?",
	"State or Local Agency/Agencies Explanation",
	"Submission Status",
	"Submit Date",
	"Users Explanation",
	"Web Beacons - Collects PII?",
	"Web Bugs - Collects PII?",
	"Within HHS Explanation"
) COMMENT='Current Privacy Impact Assessment(PIA) gather from core.PIAhist table for CEDE '
 as
SELECT 
csnap.REPORT_DATE as ReportDate 
,CFACTS_System.Authorization_Package  as "Authorization_Package"
,CFACTS_PIA.PIA_Tracking_ID  as "Tracking ID"
,NULL as "Administrators Explanation"
,NULL as "ATO Expiration Date"
,NULL as "Authorization_Package: ISSO - ISSOCS"
,CFACTS_PIA.Final_Approver  as "CMS Final Approver"
,CFACTS_PIA.Final_Approver_Date  as "CMS Final Approver Date"
,CFACTS_PIA.Final_Approver_Status  as "CMS Final Approver Review Status"
,NULL as "CMS SOP"
,NULL as "Component"
,NULL as "Contractors Explanation"
,CFACTS_PIA.Review_Status  as "CRA Review Status"
,CFACTS_PIA.Reviewer  as "CRA Reviewer"
,NULL as "Created By"
,NULL as "Default Record Permissions"
,NULL as "Developers Explanation"
,NULL as "Does the PIA have an Expiration Date?"
,NULL as "Form Date"
,NULL as "Helper PIA-014"
,NULL as "Helper XLC Phase = Disposition for Notifications"
,CFACTS_PIA.HHS_PIA_Review_Date  as "HHS PIA Review Date"
,CFACTS_PIA.HHS_PIA_Status  as "HHS PIA Review Status"
,NULL as "HHS PIA Reviewer"
,NULL as "HHS PIA Tracker Comments"
,NULL as "Inherited Record Permissions"
,NULL as "Is this a PIA Renewal?"
,NULL as "ISSO Submitter"
,NULL as "Last Updated"
,NULL as "Original - PIA-014"
,NULL as "Other - Collects PII?"
,NULL as "Other Federal Agency/Agencies Explanation"
,NULL as "Others Explanation"
,CFACTS_PIA.Overall_Status  as "Overall_Status"
,NULL as "Persistent Cookies - Collects PII?"
,NULL as "PIA Expiration Date"
,NULL as "PIA-001"
,NULL as "PIA-002"
,NULL as "PIA-002a"
,NULL as "PIA-003"
,NULL as "PIA-003a"
,NULL as "PIA-003b"
,NULL as "PIA-004"
,NULL as "PIA-005"
,NULL as "PIA-006a"
,NULL as "PIA-006b"
,NULL as "PIA-006c"
,NULL as "PIA-006d"
,NULL as "PIA-006e"
,NULL as "PIA-007"
,NULL as "PIA-008"
,NULL as "PIA-008a"
,NULL as "PIA-008b"
,NULL as "PIA-009"
,NULL as "PIA-010"
,NULL as "PIA-011"
,NULL as "PIA-012"
,NULL as "PIA-013"
,NULL as "PIA-014"
,NULL as "PIA-015"
,NULL as "PIA-016"
,NULL as "PIA-017"
,NULL as "PIA-018"
,NULL as "PIA-019"
,NULL as "PIA-020"
,NULL as "PIA-020a"
,NULL as "PIA-021"
,NULL as "PIA-022"
,NULL as "PIA-022a"
,NULL as "PIA-022ai"
,NULL as "PIA-023"
,NULL as "PIA-023a"
,NULL as "PIA-023ii"
,NULL as "PIA-023iii"
,NULL as "PIA-024"
,NULL as "PIA-024a"
,NULL as "PIA-024b"
,NULL as "PIA-024c"
,NULL as "PIA-025"
,NULL as "PIA-026"
,NULL as "PIA-027"
,NULL as "PIA-028"
,NULL as "PIA-029"
,NULL as "PIA-030"
,NULL as "PIA-031"
,NULL as "PIA-032"
,NULL as "PIA-033"
,NULL as "PIA-034"
,NULL as "PIA-035"
,NULL as "PIA-036"
,NULL as "PIA-037"
,NULL as "PIA-038"
,NULL as "PIA-039"
,NULL as "PIA-040"
,NULL as "PIA-040a"
,NULL as "PIA-041"
,NULL as "PIA-041a"
,NULL as "PIA-042"
,NULL as "PIA-042a"
,NULL as "PIA-043"
,NULL as "PIA-043a"
,NULL as "PIARev-001"
,NULL as "PIARev-002"
,NULL as "PIARev-003"
,NULL as "PIARev-004"
,NULL as "PIARev-005"
,NULL as "PIARev-006"
,NULL as "PIARev-007"
,NULL as "PIARev-008"
,NULL as "PIARev-009"
,NULL as "PIARev-010"
,NULL as "PIARev-011"
,NULL as "PIARev-012"
,NULL as "Privacy Threshold Analysis (PTA)"
,NULL as "Private Sector Explanation"
,NULL as "Recent Date of Return to CMS by Department"
,NULL as "Recent Date of Submittal by CMS"
,NULL as "Record Status"
,NULL as "Require HHS PIA Status Field Trigger"
,NULL as "Review Date"
,NULL as "Session Cookies - Collects PII?"
,NULL as "State or Local Agency/Agencies Explanation"
,CFACTS_PIA.Submission_Status  as "Submission Status"
,CFACTS_PIA.Submission_Date  as "Submit Date"
,NULL as "Users Explanation"
,NULL as "Web Beacons - Collects PII?"
,NULL as "Web Bugs - Collects PII?"
,NULL as "Within HHS Explanation"
from table(CORE.FN_CRM_GET_REPORT_ID(0)) csnap
JOIN CORE.SystemsHist CFACTS_System on CFACTS_System.REPORT_ID = csnap.REPORT_ID
JOIN PIAHist CFACTS_PIA on CFACTS_PIA.REPORT_ID = csnap.REPORT_ID and CFACTS_PIA.SYSTEM_ID = CFACTS_System.SYSTEM_ID
;