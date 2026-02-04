create or replace view VW_ASSET_SOFTWARE_DETAILS(
	ACRONYM,
	DATACENTERACRONYM,
	ACR_ALIAS,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	IS_DATACENTER,
	IS_MARKETPLACE,
	HVASTATUS,
	MEFSTATUS,
	TLC_PHASE,
	SOURCE_TOOL_LASTSEEN,
	ENVIRONMENT,
	ASSET_ID_TATTOO,
	OS_VERSION,
	TENABLEUUID,
	DEVICETYPE,
	INSERT_DATE,
	LASTSEEN_HWAM,
	IS_APPLICABLE,
	DEVICEROLE,
	FQDN,
	HOSTNAME,
	IPV4,
	IPV6,
	MACADDRESS,
	NETBIOSNAME,
	AWS_INSTANCESTATUS,
	IS_TENABLE_CREDENTIALED_SCAN,
	LASTSEEN,
	FIRSTSEEN,
	DATEINSTALLED,
	DW_SWAM_ID,
	SOFTWARENAME
) COMMENT='This view contains Master Device records data along with Sofware name for SWAM details'
 as
select
sys.Acronym
,dc.Acronym as DatacenterAcronym
,substring(sys.Acronym,1,1) || '***' as Acr_Alias
,sys.Component_Acronym
,sys.Group_Acronym
,sys.Is_DataCenter
,sys.Is_MarketPlace
,sys.HVAStatus
,sys.MEFStatus
,sys.TLC_Phase
,a.SOURCE_TOOL_LASTSEEN
,upper(a.environment) as environment
,a.asset_id_tattoo
,a.os_version
,a.TenableUUID
,a.DeviceType
,a.INSERT_DATE
,a.LastSeen_HWAM
,a.IS_APPLICABLE
,a.DeviceRole
,a.fqdn
,a.hostname
,a.IPv4
,a.IPv6
,a.Macaddress
,a.netbiosname 
,a.AWS_INSTANCESTATUS
,asw.is_tenable_credentialed_scan
,asw.LASTSEEN
,asw.FIRSTSEEN
,ASW.DATEINSTALLED
,asw.DW_SWAM_ID
,asw.SOFTWARENAME
from CORE.VW_ASSETS a
JOIN CORE.VW_ASSET_SOFTWARE asw on a.dw_asset_id = asw.dw_asset_id
right outer join (select SYSTEM_ID,Acronym,Component_Acronym,Is_DataCenter,Is_MarketPlace,HVAStatus,MEFStatus,Group_Acronym,TLC_Phase,aws_accountids,IS_EXCLUDEFROMREPORTING from CORE.vw_Systems) sys ON sys.SYSTEM_ID = a.SYSTEM_ID 
left join (select SYSTEM_ID,acronym from CORE.vw_Systems) dc ON dc.SYSTEM_ID = a.DATACENTER_ID
;