create or replace view VW_CDM_DASHBOARD(
	SYSTEM_ID,
	DATACENTER_ID,
	ASSETHIST_ID,
	DW_ASSET_ID,
	REPORT_ID,
	IS_SCANNABLE,
	ACRONYM,
	ACR_ALIAS,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	IS_DATACENTER,
	IS_MARKETPLACE,
	HVASTATUS,
	MEFSTATUS,
	TLC_PHASE,
	IS_EXCLUDEFROMREPORTING,
	RANKK,
	REFRESH_DATE,
	COMPUTER_TYPE,
	OS,
	BIOS_GUID,
	SOURCE_TOOL_LASTSEEN,
	ENVIRONMENT,
	ASSET_ID_TATTOO,
	OS_VERSION,
	TENABLEUUID,
	DEVICETYPE,
	INSERT_DATE,
	DATEDELETED,
	IS_APPLICABLE,
	DEVICEROLE,
	FQDN,
	HOSTNAME,
	IPV4,
	IPV6,
	MACADDRESS,
	NETBIOSNAME,
	AWS_INSTANCESTATUS,
	NETBIOS_HN,
	DATACENTER,
	VRT,
	SNAPSHOTS,
	ENDOFMONTH,
	REPORT_DATE,
	STARTOFMONTH,
	LASTSEEN_HWAM,
	REFRESHDATE,
	TENANT_ID,
	IS_TENABLE_CREDENTIALED_SCAN,
	IS_FORESCOUT_MANAGED,
	CLOUD_ACCOUNT_ID,
	IS_ENDPOINT
) COMMENT='This view contains Master Device records data along with Vuln risk tolerance calculated at each asset level'
 as
with
ReportIDs as ((select Report_ID,Report_Date, snapshot_ID, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date,Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where DataCategory= 'HWAM')a where rankkForSnap =1
	union --CR#822 changed Union All to Union to avoid duplicate records on monthend snapshot date
	select Report_ID,Report_Date, snapshot_ID, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date, Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where Is_endOfMonth =1 and DataCategory= 'HWAM')a where rankkForSnap<=3)),
    
Snapshots as (select Report_ID, snapshot_ID,
	case when dense_rank()over(order by Report_ID desc) = 1 then 'Current' when dense_rank()over(order by Report_ID desc) ='2' then 'LastMonth' when  dense_rank()over(order by Report_ID desc) ='3' then 'PrevMonth' when  dense_rank()over(order by Report_ID desc) ='4' then  'PrevPrevMonth' end as SnapshotsRank,
	case when dense_rank()over(order by Report_ID desc) =1 then LAST_DAY(current_date()) else LAST_DAY(ADD_MONTHS(Report_Date,-1)) end as EndofMonth,
	r.Report_Date,
	case when dense_rank()over(order by Report_ID desc) =1 then DATE_TRUNC('MONTH',current_date()) else (DATE_TRUNC('MONTH',ADD_MONTHS(Report_Date,-1))) End as StartOfMonth
	from ReportIDs r)
    
select
ah.SYSTEM_ID 
,ah.DATACENTER_ID 
,ah.ASSETHIST_ID 
,ah.dw_Asset_ID 
,ah.Report_ID
,a.Is_Scannable 
,sys.Acronym 
,substring(sys.Acronym,1,1) || '***' as Acr_Alias
,sys.Component_Acronym 
,sys.Group_Acronym 
,sys.Is_DataCenter 
,sys.Is_MarketPlace 
,sys.HVAStatus 
,sys.MEFStatus 
,sys.TLC_Phase 
,sys.IS_EXCLUDEFROMREPORTING 
,dense_rank()over(order by ah.REPORT_ID desc) as rankk
,CURRENT_TIMESTAMP() as refresh_date
,a.computer_type 
,a.os 
,a.bios_guid 
,a.SOURCE_TOOL_LASTSEEN 
,upper(a.environment) as environment
,a.asset_id_tattoo 
,a.os_version 
,a.TenableUUID 
,a.DeviceType 
,a.INSERT_DATE 
,NULL as dateDeleted
,a.IS_APPLICABLE 
,a.DeviceRole 
,a.fqdn 
,a.hostname 
,a.IPv4
,a.IPv6 
,a.Macaddress 
,a.netbiosname 
,upper(ah.AWS_INSTANCESTATUS) AWS_INSTANCESTATUS 
,ah.BIOS_GUID as netbios_hn
,dc.Acronym as Datacenter
,ah.VulnRiskTolerance as VRT
,snap.SnapshotsRank as Snapshots
,snap.EndofMonth 
,snap.Report_Date 
,snap.StartOfMonth 
,a.LastSeen_HWAM 
,current_date() as RefreshDate
,a.tenant_id 
,ah.is_tenable_credentialed_scan --cr#968
,ah.is_forescout_managed --cr#968
,a.CLOUD_ACCOUNT_ID -- 241125 CR1038
,ah.IS_ENDPOINT --241219 CR968
from CORE.VW_Assets a
RIGHT JOIN CORE.VW_ASSETHIST ah on ah.DW_ASSET_ID = a.DW_ASSET_ID 
--join CORE.reportsnapshots RC on ah.report_id = RC.REPORT_ID
JOIN Snapshots snap on snap.REPORT_ID = ah.REPORT_ID
right outer join (select SYSTEM_ID,Acronym,Component_Acronym,Is_DataCenter,Is_MarketPlace,HVAStatus,MEFStatus,Group_Acronym,TLC_Phase,aws_accountids,IS_EXCLUDEFROMREPORTING from CORE.vw_Systems) sys ON sys.SYSTEM_ID = ah.SYSTEM_ID 
left join (select SYSTEM_ID,acronym from CORE.vw_Systems) dc ON dc.SYSTEM_ID = ah.DATACENTER_ID
--left join CORE.AssetInterfaceCoalesced aic on aic.DW_ASSET_ID = a.DW_ASSET_ID;
;