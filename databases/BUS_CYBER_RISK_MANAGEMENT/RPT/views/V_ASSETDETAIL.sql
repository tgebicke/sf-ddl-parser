create or replace view V_ASSETDETAIL(
	"dw_asset_id",
	"asset_id_derived",
	"asset_id_tattoo",
	"bigfix_asset_id",
	"bios_guid",
	"cms_asset_uid",
	"computer_type",
	"DataCenter_Acronym",
	"Is_DataCenter",
	"DataCenter_Is_Phantom",
	"datacenter_id",
	"datecreated",
	"dateModified",
	"DeviceRole",
	"DeviceType",
	"environment",
	FQDN,
	"hostname",
	"last_confirmed_time",
	"motherboard_sn",
	"netbios_hn",
	"os",
	"os_cpe",
	"os_version",
	"primary_fisma_id_derived",
	"System_Acronym",
	"System_Is_Phantom",
	"primary_fisma_id",
	"primary_fisma_id_tattoo",
	"IPv4",
	"IPv6",
	"Mac",
	"source_tool",
	"source_tool_create",
	"datacenter_id_derived",
	"dependent_fisma_id",
	"VulnRiskTolerance"
) COMMENT='Contains all the asset data and Vuln risk tolerance of each asset for current snapshot'
 as
SELECT 
a.DW_ASSET_ID as "dw_asset_id"
,null as "asset_id_derived"
,a.asset_id_tattoo as "asset_id_tattoo"
,a.bigfix_asset_id as "bigfix_asset_id"
,a.bios_guid as "bios_guid"
,a.asset_id_tattoo as "cms_asset_uid"
,a.computer_type as "computer_type"
,dc.Acronym as "DataCenter_Acronym"
,dc.Is_DataCenter as "Is_DataCenter"
,dc.IS_PHANTOMSYSTEM as "DataCenter_Is_Phantom"
,a.DATACENTER_ID as "datacenter_id"
,a.INSERT_DATE as "datecreated"
,a.dateModified as "dateModified"
,dt.DeviceRole as "DeviceRole"
,dt.DeviceType as "DeviceType"
,a.environment as "environment"
,a.FQDN as "FQDN"
,a.hostname as "hostname"
,a.last_confirmed_time as "last_confirmed_time"
,a.motherboard as "motherboard_sn"
,a.netbiosname as "netbios_hn"
,a.os as "os"
,a.os_cpe as "os_cpe"
,a.os_version as "os_version"
,s.SYSTEM_ID as "primary_fisma_id_derived"
,s.Acronym as "System_Acronym"
,s.IS_PHANTOMSYSTEM as "System_Is_Phantom"
,s.SYSTEM_ID as "primary_fisma_id"
,s.SYSTEM_ID as "primary_fisma_id_tattoo"
,a.IPv4 as "IPv4"
,a.IPv6 as "IPv6"
,a.Macaddress as "Mac"
,a.source_tool_lastseen as "source_tool"
,a.source_tool_create as "source_tool_create"
,dc.SYSTEM_ID as "datacenter_id_derived"
,null as "dependent_fisma_id"
,a.VulnRiskTolerance as "VulnRiskTolerance"
FROM CORE.VW_Assets a
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
JOIN CORE.DEVICETYPES dt on dt.DEVICETYPE = a.DEVICETYPE
;