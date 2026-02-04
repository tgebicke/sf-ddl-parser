create or replace view V_CRMP_MEANTIMETOREMEDIATE(
	ID,
	"dateCreated",
	"DataCenterAcronym",
	"SnapshotDate",
	"SystemAcronym",
	"asset_id_tattoo",
	"cve",
	"CVSSv2Base",
	"CVSSv3Base",
	"DaysSinceDiscovery",
	"exploitAvailable",
	"firstSeen",
	"FISMAseverity",
	"lastFound",
	"MitigationStatus",
	OS,
	"source_tool",
	"Datacenter_id",
	"FISMA_id",
	"Group Acronym",
	"Component Acronym",
	"Is_Legacy"
) COMMENT='FIXED and CRITICAL/HIGH vulns'
 as
SELECT 
v.ID as "ID"
,r.REPORT_DATE as "dateCreated"
,dc.Acronym as "DataCenterAcronym"
,r.REPORT_DATE as "SnapshotDate"
,s.Acronym as "SystemAcronym"
,a.asset_id_tattoo as "asset_id_tattoo"
,vm.cve as "cve"
,v.CVSSV2BASESCORE as "CVSSv2Base"
,v.CVSSV3BASESCORE as "CVSSv3Base"
,vm.DaysSinceDiscovery as "DaysSinceDiscovery"
,v.exploitAvailable as "exploitAvailable"
,vm.firstSeen as "firstSeen"
,v.FISMAseverity as "FISMAseverity"
,v.lastFound as "lastFound"
,v.MitigationStatus as "MitigationStatus"
,a.OS as "OS"
,'Tenable' as "source_tool"
,dc.SYSTEM_ID as "Datacenter_id"
,s.SYSTEM_ID as "FISMA_id"
,s.Group_Acronym  as "Group Acronym"
,s.Component_Acronym  as "Component Acronym"
,vm.Is_Legacy as "Is_Legacy"
from TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.VULHIST v on v.REPORT_ID = r.REPORT_ID -- 230718 was VW_VULHIST which only returns open/reopen
join CORE.VW_VulMaster vm on vm.DW_VUL_ID = v.DW_VUL_ID
JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
where s.Is_OperationalSystem = 1 and s.Is_HighRiskSystem = 1
and upper(v.MitigationStatus) IN ('FIXED')
and upper(v.FISMAseverity) IN ('CRITICAL','HIGH')
;