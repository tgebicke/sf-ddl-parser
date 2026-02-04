create or replace view VW_ASSETINTERFACE(
	DW_ASSET_ID,
	ASSET_ID_TATTOO,
	BIGFIX_ASSET_ID,
	BIOS_GUID,
	COMPUTER_TYPE,
	DATACENTER_ACRONYM,
	IS_DATACENTER,
	DATACENTER_ID,
	DATECREATED,
	DATEMODIFIED,
	DEVICEROLE,
	DEVICETYPE,
	ENVIRONMENT,
	FQDN,
	HOSTNAME,
	LAST_CONFIRMED_TIME,
	MOTHERBOARD_SN,
	NETBIOSNAME,
	OS,
	OS_CPE,
	OS_VERSION,
	SYSTEM_ACRONYM,
	PRIMARY_FISMA_ID,
	IPV4,
	IPV6,
	MAC,
	TENABLEUUID,
	SOURCE_TOOL_CREATE,
	DEPENDENT_FISMA_ID
) COMMENT='Shows  active assets with combile interfaces (IPv4,Hostname,FQDN,MacAddress etc.)'
 as
SELECT 
Asset.DW_Asset_ID
--,Asset.asset_id_derived
,Asset.asset_id_tattoo
,Asset.bigfix_asset_id
,Asset.bios_guid
--,Asset.Val_asset_uid as cms_asset_uid
,Asset.computer_type
,cd.Acronym as DataCenter_Acronym
,cd.Is_DataCenter
--,cd.Is_PhantomSystem as DataCenter_Is_Phantom
,cd.SYSTEM_ID as datacenter_id
,Asset.INSERT_DATE as datecreated
,Asset.dateModified
,dr.DeviceRole
,dt.DeviceType
,Asset.environment
,ai.fqdn
,ai.hostname
,Asset.last_confirmed_time
,Asset.motherboard as motherboard_sn
,ai.netbiosname
,Asset.os
,Asset.os_cpe
,Asset.os_version
,cf.Acronym as System_Acronym
--,cf.Is_PhantomSystem as System_Is_Phantom
,cf.SYSTEM_ID as primary_fisma_id
,ai.IPv4
,ai.IPv6
,ai.Macaddress as Mac
,Asset.TenableUUID
--,Asset.DataSourceID_ins
--,Asset.DataSourceID_upd
--,Asset.source_tool
,Asset.source_tool_create
,NULL as dependent_fisma_id 
--,Asset.datacenter_id
--,Asset.primary_fisma_id
FROM CORE.VW_Assets Asset
JOIN CORE.VW_Systems cd on cd.SYSTEM_ID = Asset.datacenter_id
JOIN CORE.VW_Systems cf on cf.SYSTEM_ID = Asset.SYSTEM_ID
JOIN DeviceTypes dt on dt.DEVICETYPE = Asset.DeviceType 
JOIN DeviceRoles dr on dr.DEVICEROLE = dt.DeviceRole
LEFT OUTER JOIN CORE.ASSETINTERFACECOALESCED ai on ai.DW_Asset_ID = Asset.DW_Asset_ID;