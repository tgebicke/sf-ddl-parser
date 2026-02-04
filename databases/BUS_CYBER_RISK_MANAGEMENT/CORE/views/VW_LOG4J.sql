create or replace view VW_LOG4J(
	DATEVULMASTERCREATED,
	SNAPSHOT_DATE,
	PLUGIN_ID,
	CVE,
	MITIGATIONSTATUS,
	DATEMITIGATED,
	DATEREOPENED,
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
	TENABLEUUID,
	ASSET_ID_TATTOO,
	FQDN,
	HOSTNAME,
	NETBIOSNAME,
	IPV4,
	DEVICETYPE,
	SOURCE_TOOL_CREATE,
	OS,
	LASTSEEN_HWAM,
	LASTSEEN_VUL,
	DAYS_BTW_HWAM_AND_VUL,
	LAST_CONFIRMED_TIME,
	DAYSSINCELASTCONFIRMED,
	DW_ASSET_ID,
	DW_VUL_ID
) COMMENT='Shows all assets affected by LOG4j vuln (CVE-2021-44228)'
 as
select TOP 100000 *
FROM 
(
SELECT 
vm.INSERT_DATE dateVulMasterCreated
,(select MAX(SNAPSHOT_DATE) FROM CORE.SNAPSHOT_IDS where DataCategory = 'VUL') as SNAPSHOT_DATE
,plugs.plugin_ID
,vm.cve
,vm.MitigationStatus
,vm.datemitigated
,vm.dateReopened
,a.DataCenter_Acronym
,a.System_Acronym
,a.TenableUUID
,a.asset_id_tattoo
,a.fqdn
,a.hostname
,a.netbiosname
,a.IPv4
,a.DeviceType
,a.source_tool_create
,a.os
,a.LastSeen_HWAM 
,a.lastSeen_VUL 
,DATEDIFF(d,a.lastSeen_VUL, a.LastSeen_HWAM) Days_Btw_HWAM_and_VUL 
,a.last_confirmed_time
,DATEDIFF(d,a.last_confirmed_time, CURRENT_TIMESTAMP) DaysSinceLastConfirmed 
,a.dw_asset_id
,vm.DW_VUL_ID
FROM CORE.VULPLUGINS_COALESCED plugs  -- VulPlugins plugs
join CORE.VW_VulMaster vm on vm.DW_VUL_ID = plugs.DW_VUL_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = vm.DATACENTER_ID
JOIN CORE.VW_Assets a on a.dw_asset_id = vm.DW_ASSET_ID -- and a.Is_Applicable = 1
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID -- PRIMARY_FISMA_ID

where vm.CVE = 'CVE-2021-44228' --and vm.DeletionReason IS NULL
) x

ORDER BY x.DataCenter_Acronym
,x.System_Acronym
,x.fqdn;