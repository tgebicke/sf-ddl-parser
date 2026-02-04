create or replace view "V_ISPG-DIR_POAM"(
	"Authorization Package",
	POAM_ID,
	"Overall Status",
	"Weakness Risk Level",
	POAM_CLOSED_DATE,
	"Allocated Control",
	DAYS_OPEN
) COMMENT='POAMs related data '
 as
SELECT 
 a.Authorization_Package_Name as "Authorization Package"
,p.POAM_ID
,eOverallStatus.Value as "Overall Status" 
,eRiskLevel.Value as "Weakness Risk Level"
,P.POAM_Closed_Date
,Alloc.Control_Number as "Allocated Control"
,P.Days_Open
FROM APP_CFACTS.SHARED.SEC_VW_POAMS p 
INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Authorization_Package_x_Authorization_Package_POAMs pa  ON p.ContentId=pa.POAMs_Authorization_Package_ContentId
INNER JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package a  ON a.ContentId=pa.Authorization_Package_POAMs_ContentId

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Overall_Status pOverallStatus  on pOverallStatus.ParentContentId = p.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Status_9 eOverallStatus  on eOverallStatus.Id =  pOverallStatus.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Risk_Level_1 pRiskLevel  on pRiskLevel.ParentContentId = p.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Risk_Level_1 eRiskLevel  on eRiskLevel.ID = pRiskLevel.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Allocated_Controls_Control_Standards_POAM_x_POAMs_Allocated_Control pAlloc  on pAlloc.POAMs_Allocated_Control_ContentId= p.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Allocated_Controls_Control_Standards Alloc  on Alloc.ContentId = pAlloc.Allocated_Controls_POAM_ContentId;