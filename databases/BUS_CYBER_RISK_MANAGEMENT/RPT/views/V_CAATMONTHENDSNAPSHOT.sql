create or replace view V_CAATMONTHENDSNAPSHOT(
	ID,
	"ReportID",
	"ReportDate",
	"Archer_Tracking_ID",
	"Assessment_Audit_Company",
	"Authorization_Package",
	CAAT_ID,
	"Date_Identified",
	"Finding_Description",
	"Finding_ID",
	"Finding_Title",
	"Related_POA&Ms",
	"Source",
	"Test_Method",
	"Test_Objective",
	"Test_Result",
	"Weakness_Description",
	"FK_SystemID",
	CFACTS_UID
) COMMENT='CAAT related information for the previous month end snapshot (generated on first working day of every month) sourced from CFACTS'
 as
SELECT 
caat.ID as "ID"
,caat.REPORT_ID as "ReportID"
,r.report_date as "ReportDate"
,s.Archer_Tracking_ID as "Archer_Tracking_ID"
,caat.Assessment_Audit_Company as "Assessment_Audit_Company"
,s.Authorization_Package as "Authorization_Package"
,caat.CAAT_ID as "CAAT_ID"
,caat.Date_Identified as "Date_Identified"
,caat.Finding_Description as "Finding_Description"
,caat.Finding_ID as "Finding_ID"
,caat.Finding_Title as "Finding_Title"
,caat.Related_POAMS as "Related_POA&Ms"
,caat.SOURCE_AUDIT_TYPE as "Source"
,caat.Test_Method as "Test_Method"
,caat.Test_Objective as "Test_Objective"
,caat.Test_Result as "Test_Result"
,caat.Weakness_Description as "Weakness_Description"
,caat.SYSTEM_ID as "FK_SystemID"
,caat.SYSTEM_ID as "CFACTS_UID"
FROM CORE.CAATHIST caat
JOIN CORE.REPORT_IDS r on r.REPORT_ID = caat.REPORT_ID and r.IS_ENDOFMONTH = 1
LEFT OUTER JOIN CORE.VW_Systems s on s.SYSTEM_ID = caat.SYSTEM_ID;