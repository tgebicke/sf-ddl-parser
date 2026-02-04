create or replace view V_CAPM(
	"Component",
	"Component Acronym",
	"Primary CRA",
	"TLC Phase",
	"FISMA System",
	"FISMA System Acronym",
	"CFACTS Creation Date",
	"Pen Test Final Report Date",
	"ACT Final Report Date",
	LAST_ACT_SCA_CAAT_PROCESSED_FILE_DATE,
	LAST_PENTEST_CAAT_PROCESSED_FILE_DATE,
	"Reason for ATO Request",
	"ISSO Submission",
	"SOP Review Date",
	"BO Review Date",
	"ATO Review Date",
	"CRA Review Date",
	"ISSO Review Date",
	"BO Recommendation Review Date",
	"DSPPO Review Date",
	"DSPC Review Date",
	"CISO Review Date",
	"Authorization Memo Signed Date",
	DATE_AUTH_MEMO_EXPIRES,
	"ATO Expiration Date",
	BUSINESS_OWNER,
	PRIMARY_ISSO,
	"Workflow Plase"
) COMMENT='Contains data related to CMS ATO performance metrics including ATO approval process along with important dates'
 as 
SELECT 
s.COMPONENT_NAME as "Component"
,s.COMPONENT_ACRONYM as "Component Acronym"
,CRA as "Primary CRA"
,TLC_Phase as "TLC Phase"
,FISMA_System as "FISMA System"
,s.Acronym as "FISMA System Acronym"
,s.First_Published_Date as "CFACTS Creation Date"
,s.Last_Pentest_Date as "Pen Test Final Report Date"
,s.Last_ACT_Date as "ACT Final Report Date"
,s.Last_ACT_SCA_CAAT_Processed_File_Date
,s.Last_Pentest_CAAT_Processed_File_Date
,Reason_for_ATO_Request as "Reason for ATO Request"
,ISSO_SUBMISSION_DATE as "ISSO Submission"
,SOP_Review_Date as "SOP Review Date"
,BO_Review_Date as "BO Review Date"
,ATO_Review_Date as "ATO Review Date"
,CRA_Review_Date as "CRA Review Date"
,ISSO_Review_Date as "ISSO Review Date"
,BO_Recommendation_Review_Date as "BO Recommendation Review Date"
,DSPPO_Review_Date as "DSPPO Review Date"
,DSPC_Review_Date as "DSPC Review Date"
,CISO_Review_Date as "CISO Review Date"
,Authorization_Memo_Signed_Date as "Authorization Memo Signed Date"
,s.Date_Auth_Memo_Expires
,ATO_Expiration_Date as "ATO Expiration Date"
,s.Business_Owner
,s.Primary_ISSO
,IFF( Authorization_Memo_Signed_Date is not null ,'Approve',
IFF(SOP_Review_Date is not null
OR BO_Review_Date is not null
OR ATO_Review_Date is not null
OR CRA_Review_Date is not null
OR ISSO_Review_Date is not null
OR BO_Recommendation_Review_Date is not null
OR DSPPO_Review_Date is not null
OR DSPC_Review_Date is not null
OR CISO_Review_Date is not null, 'Review',
IFF(ISSO_SUBMISSION_DATE is not null ,'Validate',
IFF(s.Last_Pentest_Date is not null 
OR s.Last_ACT_Date is not null,'Assessment',
NULL)))) as "Workflow Plase"
FROM CORE.VW_Systems s
;