create or replace view "V_ISPG-DIR_RBD"(
	"Risk Acceptance ID",
	"Information System or Program Name",
	"Submit Date",
	"Weakness Risk Level",
	"POA&Ms",
	"Days to Expiration",
	"Expiration Date"
) COMMENT='ISPG-DIR RBD'
 as
SELECT RBD.Risk_Acceptance_ID as "Risk Acceptance ID"
	  ,RBD.Authorization_Package_Name as "Information System or Program Name"
      ,RBD.Submit_Date as "Submit Date"
	  ,enumRiskLevel.Value as "Weakness Risk Level"
	  ,POAM.POAM_ID as "POA&Ms"
	  ,RBD.Days_to_Expiration as "Days to Expiration"
      ,RBD.Expiration_Date as "Expiration Date"
	  FROM APP_CFACTS.SHARED.SEC_VW_Risk_Acceptance_RBD RBD  
      join APP_CFACTS.SHARED.SEC_VW_POAMs_Risk_Acceptance_RBD_POAMs_x_Risk_Acceptance_RBD_POAMs RBDXPOAM 
	        on RBD.ContentId= RBDXPOAM.Risk_Acceptance_RBD_POAMs_ContentId
	  join APP_CFACTS.SHARED.SEC_VW_POAMs POAM  on RBDXPOAM.POAMs_Risk_Acceptance_RBD_POAMs_ContentId=POAM.ContentId
	  join APP_CFACTS.SHARED.SEC_VW_POAMs_Weakness_Risk_Level_1 RiskLevel on RiskLevel.ParentContentId=POAM.ContentId
	  join APP_CFACTS.SHARED.SEC_VW_enum_Risk_Level_1 enumRiskLevel  on enumRiskLevel.Id=RiskLevel.Value;