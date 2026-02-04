create or replace view V_VULHIST(
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
	"datemitigated",
	REPORT_ID,
	DW_ASSET_ID,
	DW_VUL_ID
) COMMENT='Return open/reopened historical vulnerability for all report_id'
 as
SELECT 
ID as "ID"
,REPORT_DATE as "dateCreated"
,DATACENTERACRONYM as "DataCenterAcronym"
,REPORT_DATE as "SnapshotDate"
,SYSTEMACRONYM as "SystemAcronym"
,ASSET_ID_TATTOO as "asset_id_tattoo"
,CVE as "cve"
,CVSSV2BASESCORE as "CVSSv2Base"
,CVSSV3BASESCORE as "CVSSv3Base"
,DAYSSINCEDISCOVERY as "DaysSinceDiscovery"
,DESCRIPTION as "Description"
,DNSNAME as "dnsName"
,EXPLOITAVAILABLE as "exploitAvailable"
,FAMILYNAME as "familyName"
,FIRSTSEEN as "firstSeen"
,FISMASEVERITY as "FISMAseverity"
,IP as "ip"
,LASTFOUND as "lastFound"
,MACADDRESS as "macAddress"
,MITIGATIONSTATUS as "MitigationStatus"
,NETBIOSNAME as "netbiosname"
,OS as "OS"
,PLUGIN_ID as "pluginID"
,SIGNATURE as "signature"
,SOLUTION as "Solution"
,SOURCE_TOOL as "source_tool"
,DATACENTER_ID as "Datacenter_id"
,SYSTEM_ID as "FISMA_id"
,GROUP_ACRONYM as "Group Acronym"
,GROUP_NAME as "Group Name"
,COMPONENT_ACRONYM as "Component Acronym"
,COMPONENT_NAME as "Component Name"
,case IS_BOD
    when TRUE then 'Yes'
    Else 'No'
End as "Is_BOD"
,BODDUEDATE as "BODDueDate"
,DATEMITIGATED as "datemitigated"
,REPORT_ID as REPORT_ID -- New under SDL
,DW_ASSET_ID as DW_ASSET_ID -- New under SDL
,DW_VUL_ID as DW_VUL_ID -- New under SDL
FROM CORE.VW_VULHIST;