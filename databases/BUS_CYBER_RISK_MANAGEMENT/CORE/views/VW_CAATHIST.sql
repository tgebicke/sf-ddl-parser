create or replace view VW_CAATHIST(
	ID,
	REPORTID,
	REPORTDATE,
	ARCHER_TRACKING_ID,
	ASSESSMENT_AUDIT_COMPANY,
	AUTHORIZATION_PACKAGE,
	CAAT_ID,
	DATE_IDENTIFIED,
	FINDING_DESCRIPTION,
	FINDING_ID,
	FINDING_TITLE,
	RELATED_POAMS,
	SOURCE_AUDIT_TYPE,
	TEST_METHOD,
	TEST_OBJECTIVE,
	TEST_RESULT,
	WEAKNESS_DESCRIPTION,
	SYSTEM_ID
) COMMENT='Current CAAT records taken from core.CAAThist table'
 as
SELECT caat.ID
,rep.Report_ID as ReportID
,rep.Report_Date as ReportDate
,s.Archer_Tracking_ID
,caat.Assessment_Audit_Company
,s.Authorization_Package
,caat.CAAT_ID
,caat.Date_Identified
,caat.Finding_Description
,caat.Finding_ID
,caat.Finding_Title
,caat.Related_POAMS
,caat.SOURCE_AUDIT_TYPE
,caat.Test_Method
,caat.Test_Objective
,caat.Test_Result
,caat.Weakness_Description
,s.SYSTEM_ID
FROM CORE.CAATHist caat
join TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) rep on rep.Report_ID = caat.REPORT_ID 
LEFT OUTER JOIN CORE.VW_Systems s on s.SYSTEM_ID = caat.SYSTEM_ID;