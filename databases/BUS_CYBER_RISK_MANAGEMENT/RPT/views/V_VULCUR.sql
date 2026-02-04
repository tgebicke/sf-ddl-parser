create or replace view V_VULCUR(
	DW_VUL_ID,
	DATEVULCREATED,
	DATACENTERACRONYM,
	SNAPSHOT_DATE,
	SYSTEMACRONYM,
	ASSET_ID_TATTOO,
	CVE,
	CVSSV2BASE,
	CVSSV3BASE,
	DAYSSINCEDISCOVERY,
	DESCRIPTION,
	DNSNAME,
	EXPLOITAVAILABLE,
	FAMILYNAME,
	FIRSTSEEN,
	FISMASEVERITY,
	IP,
	LASTFOUND,
	MACADDRESS,
	MITIGATIONSTATUS,
	NETBIOSNAME,
	OS,
	PLUGINID,
	SIGNATURE,
	SOLUTION,
	SOURCE_TOOL,
	DATACENTER_ID,
	FISMA_ID,
	"GROUP ACRONYM",
	"GROUP NAME",
	"COMPONENT ACRONYM",
	"COMPONENT NAME",
	IS_BOD,
	BODDUEDATE,
	DATEMITIGATED,
	DW_ASSET_ID,
	SNAPSHOT_ID
) COMMENT='current open or reopened vulns'
 as
SELECT 
vm.dw_vul_id 
,vm.INSERT_DATE as dateVulCreated 
,dc.Acronym as DataCenterAcronym
,(SELECT TOP 1 REPORT_DATE FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as SNAPSHOT_DATE
,s.Acronym as SystemAcronym
,a.asset_id_tattoo
,vm.cve
,vm.CVSSV2BASESCORE as CVSSv2Base
,vm.CVSSV3BASESCORE as CVSSv3Base
,vm.DaysSinceDiscovery
,NULL as Description
,a.FQDN as dnsName
,vm.exploitAvailable
,NULL as familyName
,vm.firstSeen
,vm.FISMAseverity
,a.IPv4 as ip
,vm.lastFound
,a.macAddress
,vm.MitigationStatus
,a.netbiosname
,a.OS
,plugs.PLUGIN_ID as pluginID
,NULL as signature
,NULL as Solution
,a.source_tool_VUL as source_tool
,dc.SYSTEM_ID as Datacenter_id
,s.SYSTEM_ID as FISMA_id
,s.Group_Acronym
,s.Group_Name
,s.Component_Acronym 
,s.Component_Name 
,vm.IS_KEV as Is_BOD 
,vm.BODDueDate
,vm.datemitigated 
,vm.DW_ASSET_ID -- needed for V_Monthly_CRR_VulnCount
,((SELECT TOP 1 REPORT_ID FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)))) as SNAPSHOT_ID -- needed for V_Monthly_CRR_VulnCount
from CORE.VW_VulMaster vm
JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID 
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
LEFT OUTER JOIN CORE.VulPlugin plugs on plugs.DW_VUL_ID = vm.DW_VUL_ID
where vm.MitigationStatus IN ('open','reopened')
;