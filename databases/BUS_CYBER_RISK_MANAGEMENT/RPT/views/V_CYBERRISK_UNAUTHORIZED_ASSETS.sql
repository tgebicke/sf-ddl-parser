create or replace view V_CYBERRISK_UNAUTHORIZED_ASSETS(
	"DataCenter_Acronym",
	"datacenter_id",
	"System_Acronym",
	"primary_fisma_id",
	"TLC_Phase",
	"Primary_Operating_Location",
	ISSO,
	CRA,
	"dw_asset_id",
	"asset_id_tattoo",
	"bigfix_asset_id",
	"computer_type",
	"datecreated",
	"dateModified",
	"DeviceRole",
	"DeviceType",
	"environment",
	"fqdn",
	"hostname",
	"last_confirmed_time",
	"motherboard_sn",
	"netbiosname",
	"os",
	"os_cpe",
	"os_version",
	"IPv4",
	"IPv6",
	"Mac",
	"TenableUUID",
	"source_tool",
	"source_tool_create"
) COMMENT='Assets that are being reported and belong to retired systems'
 as
select 
cd.Acronym as "DataCenter_Acronym"
,cd.SYSTEM_ID as "datacenter_id"
,cf.Acronym as "System_Acronym"
,cf.SYSTEM_ID as "primary_fisma_id"
,cf.TLC_Phase as "TLC_Phase"
,cf.Primary_Operating_Location as "Primary_Operating_Location"
,cf.ISSO as "ISSO"
,cf.CRA as "CRA"
,a.DW_ASSET_ID as "dw_asset_id"
,a.asset_id_tattoo as "asset_id_tattoo"
,a.bigfix_asset_id as "bigfix_asset_id"
,a.computer_type as "computer_type"
,a.INSERT_DATE as "datecreated"
,a.dateModified as "dateModified"
,a.DeviceRole as "DeviceRole"
,a.DeviceType as "DeviceType"
,a.environment as "environment"
,a.fqdn as "fqdn"
,a.hostname as "hostname"
,a.last_confirmed_time as "last_confirmed_time"
,a.motherboard as "motherboard_sn"
,a.netbiosname as "netbiosname"
,a.os as "os"
,a.os_cpe as "os_cpe"
,a.os_version as "os_version"
,a.IPv4 as "IPv4"
,a.IPv6 as "IPv6"
,a.Macaddress as "Mac"
,a.TenableUUID as "TenableUUID"
,a.source_tool_lastseen as "source_tool"
,a.source_tool_create as "source_tool_create"
FROM CORE.VW_Assets a
JOIN CORE.VW_Systems cd on cd.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems cf on cf.SYSTEM_ID = a.SYSTEM_ID
Where (cd.TLC_Phase = 'Retire' or cf.TLC_Phase = 'Retire') 
order by cd.Acronym
,cf.Acronym
,a.DW_ASSET_ID;