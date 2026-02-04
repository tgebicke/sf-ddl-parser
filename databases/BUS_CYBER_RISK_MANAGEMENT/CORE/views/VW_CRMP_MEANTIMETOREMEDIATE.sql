create or replace view VW_CRMP_MEANTIMETOREMEDIATE(
	ID,
	DATACENTERACRONYM,
	SNAPSHOT_DATE,
	SYSTEMACRONYM,
	ASSET_ID_TATTOO,
	CVE,
	CVSSV2BASESCORE,
	CVSSV3BASESCORE,
	DAYSSINCEDISCOVERY,
	EXPLOITAVAILABLE,
	FIRSTSEEN,
	FISMASEVERITY,
	LASTFOUND,
	MITIGATIONSTATUS,
	OS,
	SOURCE_TOOL_LASTSEEN,
	DATACENTER_ID,
	FISMA_ID,
	GROUP_ACRONYM,
	COMPONENT_ACRONYM,
	IS_LEGACY
) COMMENT='Shows  high and critical fixed vulnerability of high risk systems assets used for CRMP.'
 as
SELECT 
vm.DW_VUL_ID as ID
--,vm.INSERT_DATE
,dc.Acronym as DataCenterAcronym
,(select REPORT_DATE from table(CORE.FN_CRM_GET_REPORT_ID(0))) as SNAPSHOT_DATE
,s.Acronym as SystemAcronym
,a.asset_id_tattoo
,vm.cve
,vm.CVSSV2BASESCORE -- 231027 renamed
,vm.CVSSV3BASESCORE -- 231027 renamed
,vm.DaysSinceDiscovery
,vm.exploitAvailable
,vm.firstSeen
,vm.FISMAseverity
,vm.lastFound
,vm.MitigationStatus
,a.OS
,vm.LASTFOUND as source_tool_lastseen -- IS THIS OK??????
,dc.SYSTEM_ID as Datacenter_id
,s.SYSTEM_ID as FISMA_id
,s.Group_Acronym 
,s.Component_Acronym 
,vm.Is_Legacy
from CORE.VW_VulMaster vm 
JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
where s.Is_OperationalSystem = 1 and s.Is_HighRiskSystem = 1 
and lower(vm.MitigationStatus) = 'fixed'
and lower(vm.FISMAseverity) IN ('critical','high')
;