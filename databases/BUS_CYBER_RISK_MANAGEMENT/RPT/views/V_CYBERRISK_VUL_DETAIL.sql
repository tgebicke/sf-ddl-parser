create or replace view V_CYBERRISK_VUL_DETAIL(
	ID,
	DATECREATED,
	DATACENTERACRONYM,
	SNAPSHOTDATE,
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
	"Group Acronym",
	"Group Name",
	"Component Acronym",
	"Component Name",
	IS_BOD,
	BODDUEDATE,
	DATEMITIGATED
) COMMENT='Used to test data for Month end Cyber risk data'
 as
SELECT 
v.ID
,r.REPORT_DATE as dateCreated
,dc.Acronym as DataCenterAcronym
,r.REPORT_DATE as SnapshotDate
,s.Acronym as SystemAcronym
,ah.asset_id_tattoo
,vm.cve
,v.CVSSV2BASESCORE as CVSSV2BASE 
,v.CVSSV3BASESCORE as CVSSV3Base
,v.DaysSinceDiscovery
,NULL as Description
,ah.FQDN as dnsName
,v.exploitAvailable
,NULL as familyName
,vm.firstSeen
,v.FISMAseverity
,ah.IPv4 as ip
,v.lastFound
,ah.MacAddress
,v.MitigationStatus
,ah.netbiosname
,ah.OS
,plugs.PLUGIN_ID as pluginID
,NULL as signature
,NULL as Solution
,ah.SOURCE_TOOL_LASTSEEN as source_tool -- column not found in CYBER_RISK_MANAGEMENT
,dc.SYSTEM_ID as Datacenter_id
,s.SYSTEM_ID as FISMA_id
,s.GROUP_ACRONYM as "Group Acronym" 
,s.GROUP_NAME as "Group Name" 
,s.COMPONENT_ACRONYM as "Component Acronym" 
,s.COMPONENT_NAME as "Component Name"
,vm.IS_KEV as Is_BOD 
,vm.BODDueDate 
,vm.datemitigated 
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) r
JOIN CORE.VW_VULHIST v on v.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_VULMASTER vm on vm.DW_VUL_ID = v.dw_vul_id
JOIN CORE.VW_ASSETHIST ah on ah.Report_ID = r.REPORT_ID and ah.DW_ASSET_ID = vm.DW_Asset_ID
--230602 CMR; LEFT OUTER JOIN CORE.ASSETINTERFACECOALESCEDHIST aic on aic.REPORT_ID = r.REPORT_ID and aic.DW_ASSET_ID = v.DW_Asset_ID
JOIN CORE.VW_SYSTEMS dc on dc.SYSTEM_ID = ah.datacenter_id
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = ah.SYSTEM_ID

LEFT OUTER JOIN (select DW_VUL_ID, listagg(DISTINCT PLUGIN_ID, ', ') WITHIN GROUP (ORDER BY PLUGIN_ID DESC) as PLUGIN_ID FROM CORE.VULPLUGIN GROUP BY DW_VUL_ID) plugs on plugs.dw_vul_id = v.dw_vul_id -- 230829 2100
-- 230829 2100 LEFT OUTER JOIN CORE.VULPLUGIN plugs on plugs.dw_vul_id = v.dw_vul_id

where v.MitigationStatus IN ('open','reopened');