create or replace view V_CYBERRISK_HWAM_DETAIL(
	DATECREATED,
	ASSET_ID_TATTOO,
	DATACENTER_ID,
	DATACENTERACRONYM,
	DATACENTER_AUTHORIZATION_PACKAGE,
	PRIMARY_FISMA_ID,
	PRIMARY_FISMA_ID_ACRONYM,
	PRIMARY_FISMA_ID_AUTHORIZATION_PACKAGE,
	COMPUTER_TYPE,
	DEVICEROLE,
	DEVICETYPE,
	ENVIRONMENT,
	FQDN,
	HOSTNAME,
	MOTHERBOARD_SN,
	NETBIOS_HN,
	OS,
	OS_CPE,
	BIOS_GUID,
	SOURCE_TOOL,
	LAST_CONFIRMED_TIME,
	IPV4,
	IPV6,
	MAC,
	FK_DATACENTER_ID,
	DATACENTER_COMMONNAME,
	FK_PRIMARY_FISMA_ID,
	PRIMARY_FISMA_ID_COMMONNAME,
	TLC_PHASE
) COMMENT='Used in other views to get the Asset details.'
 as
SELECT
a.INSERT_DATE as dateCreated -- datecreated as dateCreated
,a.asset_id_tattoo
,a.datacenter_id
,dc.Acronym as DataCenterAcronym
,dHist.Authorization_Package as datacenter_Authorization_Package
,s.SYSTEM_ID as primary_fisma_id
,s.ACRONYM as primary_fisma_id_Acronym
,dHist.Authorization_Package as primary_fisma_id_Authorization_Package
,a.computer_type as Computer_Type
,a.DeviceRole as DeviceRole
,a.DeviceType
,a.environment as Environment
,a.FQDN
,a.HostName
,a.Motherboard as Motherboard_SN
,a.netbiosname as NetBios_hn
,a.OS as OS
,a.OS_CPE
,a.bios_guid as bios_guid
,NULL as Source_Tool -- a.source_tool as Source_Tool
,a.last_confirmed_time
,a.IPv4 as IPv4
,a.IPv6 as IPv6
,a.Macaddress as Mac
,dc.SYSTEM_ID as FK_datacenter_id 
,dc.CommonName as datacenter_CommonName 
,dc.SYSTEM_ID as FK_primary_fisma_id 
,dc.CommonName as primary_fisma_id_CommonName
,dHist.TLC_Phase
FROM CORE.VW_ASSETS a
JOIN CORE.VW_SYSTEMS dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = a.SYSTEM_ID
-- 	(select SYSTEM_ID FROM CORE.VW_SYSTEMS where SYSTEM_ID =
-- 	CASE a.SYSTEM_ID
-- 		when '0000000-NotValid-0000000' then a.datacenter_id
--		Else a.SYSTEM_ID
-- 	END
-- 	)
JOIN CORE.SystemsHist dHist on dHist.System_ID = dc.SYSTEM_ID and dHist.REPORT_ID = (SELECT TOP 1 REPORT_ID FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) 
JOIN CORE.SystemsHist sHist on sHist.System_ID = s.SYSTEM_ID and sHist.REPORT_ID = dHist.REPORT_ID
;