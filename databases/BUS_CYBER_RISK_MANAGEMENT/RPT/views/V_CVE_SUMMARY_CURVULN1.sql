create or replace view V_CVE_SUMMARY_CURVULN1(
	"FK_dw_vul_number",
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
	"Description",
	"dnsName",
	"exploitAvailable",
	"familyName",
	"firstSeen",
	"FISMAseverity",
	"ip",
	"lastFound",
	"macAddress",
	"MitigationStatus",
	"netbiosname",
	OS,
	"pluginID",
	"signature",
	"Solution",
	"source_tool",
	"Datacenter_id",
	"FISMA_id",
	"Group Acronym",
	"Group Name",
	"Component Acronym",
	"Component Name",
	"Is_BOD",
	"BODDueDate",
	"datemitigated"
) COMMENT='open and reopened for HVA'
 as
SELECT
vm.DW_VUL_ID as "FK_dw_vul_number"
,vm.DW_VUL_ID as "ID"
,vm.INSERT_DATE as "dateCreated"
,dc.Acronym as "DataCenterAcronym"
,(select REPORT_DATE from TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as "SnapshotDate"
,s.Acronym as "SystemAcronym"
,a.asset_id_tattoo as "asset_id_tattoo"
,vm.cve as "cve"
,vm.CVSSV2BASESCORE as "CVSSv2Base"
,vm.CVSSV3BASESCORE as "CVSSv3Base"
,vm.DaysSinceDiscovery as "DaysSinceDiscovery"
,NULL as "Description"
,a.FQDN as "dnsName"
,vm.exploitAvailable as "exploitAvailable"
,NULL as "familyName"
,vm.firstSeen as "firstSeen"
,vm.FISMAseverity as "FISMAseverity"
,a.IPv4 as "ip"
,vm.lastFound as "lastFound"
,a.macAddress as "macAddress"
,vm.MitigationStatus as "MitigationStatus"
,a.netbiosname as "netbiosname"
,a.OS as "OS"
,plugs.PLUGIN_ID as "pluginID"
,NULL as "signature"
,NULL as "Solution"
,'Tenable' as "source_tool"
,dc.SYSTEM_ID as "Datacenter_id"
,s.SYSTEM_ID as "FISMA_id"
,s.Group_Acronym as "Group Acronym"
,s.Group_Name as "Group Name"
,s.Component_Acronym as "Component Acronym"
,s.Component_Name as "Component Name"
,case coalesce(cast(vm.IS_KEV as varchar),'No')
    when 'No' then 'No'
    Else 'Yes'
End as "Is_BOD"
,vm.BODDueDate as "BODDueDate"
,vm.datemitigated as "datemitigated"
FROM CORE.VW_Assets a
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
JOIN CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
LEFT OUTER JOIN CORE.VulPlugin plugs on plugs.DW_VUL_ID = vm.DW_VUL_ID
where vm.MitigationStatus IN ('open','reopened') and s.HVAStatus = 'Yes'
;