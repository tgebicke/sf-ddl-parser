create or replace view VW_CEDE_AUTHORIZATION_PACKAGES_240216(
	ACRONYM,
	BUSINESS_OWNER,
	COMPONENT_ACRONYM,
	CURRENTYEARHVASCORE,
	FIPS_199_OVERALL_IMPACT_RATING,
	FISMA_SYSTEM,
	AUTHORIZATION_PACKAGE,
	ISCURRENTYEARHVALIST,
	MISSIONESSENTIALFUNCTIONS_MEFS,
	PRIMARY_ISSO,
	PRIMARY_OPERATING_LOCATION,
	REPORTDATE,
	SYSTEM_DESCRIPTION,
	SYSTEMDEVELOPERMAINTAINER_SDM,
	TLC_PHASE
) COMMENT='Contains system information'
 as
SELECT 
s.Acronym 
,s.Business_Owner 
,s.Component_Acronym 
,s.HVA_SCORE as CurrentYearHVAScore
,s.FIPS_199_Overall_Impact_Rating 
,s.FISMA_System 
,s.Authorization_Package 
,s.HVASTATUS as IscurrentyearHVAlist
,s.MEF as MissionEssentialFunctions_MEFs
,s.PRIMARY_ISSO 
,s.Primary_Operating_Location 
,(select Report_Date from TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as ReportDate
,s.SYSTEM_DESCRIPTION 
,s.SDM as SystemDeveloperMaintainer_SDM
,s.TLC_Phase 
FROM CORE.VW_Systems s 
;