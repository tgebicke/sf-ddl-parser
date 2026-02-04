create or replace view V_CRMP_AUTHORIZATIONPACKAGE(
	"SnapshotDate",
	ACRONYM,
	TLC_PHASE,
	PACKAGE_TYPE,
	INFORMATIONTYPE,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	DIVISION_ACRONYM,
	FISMA_SYSTEM,
	HVASTATUS
) COMMENT='Auth package level details data'
 as
SELECT 
(select top 1 REPORT_DATE from CORE.REPORT_IDS ORDER BY REPORT_ID DESC) as SnapshotDate
,s.Acronym
,s.TLC_Phase
,s.Package_Type 
,s.Information_System_Type as InformationType
,s.Component_Acronym
,s.Group_Acronym
,s.Division_Acronym
,s.FISMA_System
,s.HVAStatus
FROM CORE.VW_SYSTEMS s
;