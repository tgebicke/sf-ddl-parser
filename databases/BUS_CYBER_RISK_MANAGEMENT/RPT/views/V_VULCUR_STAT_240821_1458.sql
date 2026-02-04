create or replace view V_VULCUR_STAT_240821_1458(
	DW_VUL_ID,
	DATEVULCREATED,
	DATACENTERACRONYM,
	SNAPSHOT_DATE,
	SYSTEMACRONYM,
	DATACENTERID,
	SYSTEM_ID,
	ASSET_ID_TATTOO,
	CVE,
	CVSSV2BASE,
	CVSSV3BASE,
	DAYSSINCEDISCOVERY,
	DESCRIPTION,
	EXPLOITAVAILABLE,
	FAMILYNAME,
	FIRSTSEEN,
	FISMASEVERITY,
	LASTFOUND,
	MITIGATIONSTATUS,
	OS,
	PLUGINID,
	SIGNATURE,
	SOLUTION,
	SOURCE_TOOL,
	DATACENTER_ID,
	FISMA_ID,
	GROUP_ACRONYM,
	GROUP_NAME,
	COMPONENT_ACRONYM,
	COMPONENT_NAME,
	IS_BOD,
	BODDUEDATE,
	DATEMITIGATED
) COMMENT='current statistics over all vulns'
 as
SELECT 
vm.dw_vul_id 
,vm.INSERT_DATE as dateVulCreated 
,dc.Acronym as DataCenterAcronym
,(SELECT max(REPORT_DATE) FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as SNAPSHOT_DATE
,s.Acronym as SystemAcronym
,dc.System_ID as DataCenterID
,s.System_ID
,a.asset_id_tattoo
,vm.cve
,vm.CVSSV2BASESCORE as CVSSv2Base
,vm.CVSSV3BASESCORE as CVSSv3Base
,vm.DaysSinceDiscovery
,NULL as Description
,vm.exploitAvailable
,NULL as familyName
,vm.firstSeen
,vm.FISMAseverity
,vm.lastFound
,vm.MitigationStatus
,a.OS
,plugs.PLUGIN_ID as pluginID -- 230808 was DW_PLUGIN_ID
,NULL as signature
,NULL as Solution
,a.source_tool_VUL as source_tool
,dc.SYSTEM_ID as Datacenter_id
,s.SYSTEM_ID as FISMA_id
,s.Group_Acronym
,s.Group_Name
,s.Component_Acronym 
,s.Component_Name 
,case vm.IS_KEV
	when 0 then 'No'
	Else 'Yes' 
End as Is_BOD 
,vm.BODDueDate 
,vm.datemitigated 
from CORE.VW_VulMaster vm
JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
LEFT OUTER JOIN CORE.VulPlugin plugs on plugs.DW_VUL_ID = vm.DW_VUL_ID
;