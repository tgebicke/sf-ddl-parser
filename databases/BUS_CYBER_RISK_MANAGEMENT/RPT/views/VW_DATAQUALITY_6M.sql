create or replace view VW_DATAQUALITY_6M(
	DATACENTER_ID,
	SYSTEM_ID,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	ACRONYM,
	ACR_ALIAS,
	DATACENTER,
	DCACR_ALIAS,
	TATOO_COUNT,
	TOTAL_ASSET,
	ASSET_ID_TATTOO_PCT,
	DC_ID_DERIVED_COUNT,
	DATACENTER_ID_DERIVED_PCT,
	P_FISMA_ID_TATTOO_COUNT,
	PRIMARY_FISMA_ID_TATTOO_PCT,
	P_FISMA_ID_DERIVED_COUNT,
	PRIMARY_FISMA_ID_DERIVED_PCT,
	FQDN_COUNT,
	FQDN_PCT,
	HOSTNAME_COUNT,
	HOSTNAME_PCT,
	MAC_COUNT,
	MAC_PCT,
	MOTHERBOARD_SN_COUNT,
	MOTHERBOARD_SN_PCT,
	NETBIOS_HN_COUNT,
	NETBIOS_HN_PCT,
	OS_COUNT,
	TOTAL_OS,
	OS_PCT,
	TLC_PHASE,
	IS_MARKETPLACE,
	MEFSTATUS,
	HVASTATUS,
	COUNT_LESS72HRS,
	COUNT_GREATER72HRS,
	TIMELINESS_PCT,
	BIGFIX_ASSET_ID_COUNT,
	BIGFIX_ASSET_ID_PCT,
	OS_CPE_COUNT,
	OS_CPE_PCT,
	BIOS_GUID_COUNT,
	BIOS_GUID_PCT,
	INSTANCESTATUS_COUNT,
	INSTANCESTATUS_PCT,
	IPV4_COUNT,
	IPV4_PCT,
	IPV6_COUNT,
	IPV6_PCT,
	REPORT_ID,
	REPORT_DATE
) COMMENT='Used for Tableau in Data Quality Dashboard:  Showing HWAM data based on completeness and Timeliness'
 as
with
ReportIDs as ((select Report_ID,Report_Date, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date,Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where DataCategory= 'HWAM')a where rankkForSnap =1
	union
	select Report_ID,Report_Date, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date, Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where Is_endOfMonth =1 and DataCategory= 'HWAM')a where rankkForSnap<=6)),
    
Snapshots as (select Report_ID,
	r.Report_Date
	from ReportIDs r) 
 --  select * from  Snapshots
    
select distinct
ah.datacenter_id,
ah.System_Id,
S.Component_Acronym as Component_Acronym
,S.Group_Acronym as Group_Acronym
,S.Acronym as Acronym
,CONCAT(SUBSTR(S.Acronym, 1, 1), '***') as Acr_Alias
,data_center.Acronym DataCenter
,CONCAT(SUBSTR(data_center.Acronym, 1, 1), '***') as DCAcr_Alias
--,dense_rank()over(order by report_id desc) as rankk,
,tatoo.tatoo_count
,tl.total_asset total_asset
,asset_id_tattoo_PCT
,dc_id_derived_count
,datacenter_id_derived_PCT
,p_fisma_id_tattoo_count
,primary_fisma_id_tattoo_PCT
,p_fisma_id_derived_count
,primary_fisma_id_derived_PCT
,fqdn_count
,fqdn_PCT
,hostname_count
,hostname_PCT
,Mac_count
,Mac_PCT
,motherboard_sn_count
,motherboard_sn_PCT
,netbios_hn_count
,netbios_hn_PCT
,os.os_count
,os.total_os
,os.os_PCT
--,s.AWS_accountIds CR #1044 241209
,s.TLC_Phase
,s.Is_MarketPlace
,s.MEFStatus
,s.HVAStatus
,tl.Count_less72Hrs
,tl.Count_greater72Hrs
,case when tl.Count_less72Hrs is not null then ROUND(Count_less72Hrs*100.0/tl.total_asset,1) 
end as Timeliness_PCT
,bigfix_asset_id_count
,bigfix_asset_id_PCT
,os_cpe_count
,os_cpe_PCT
,bios_guid_count
,bios_guid_PCT
,InstanceStatus_count
,InstanceStatus_PCT
,ipv4_count
,ipv4_PCT
,ipv6_count
,ipv6_PCT
,snap.report_id
,snap.report_date
--,coalesce(ah.AWS_ACCOUNTID,ah.AZURE_SUBSCRIPTION_ID) as CLOUD_ACCOUNT_ID -- 241125 CR1038 CR#1044 241209
--,getdate() as RefreshDate
from core.Asset a
JOIN core.ASSETHIST ah on ah.dw_asset_id = a.dw_asset_id --and a.Is_Applicable = 1 and ah.Is_Applicable = 1
join Snapshots snap on snap.report_id = ah.report_id
left join (select System_Id, datacenter_id, report_id, sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id) total_asset, count(asset_id_tattoo) tatoo_count 
,case when count(a.dw_asset_id) != 0 then
ROUND(count(asset_id_tattoo)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as asset_id_tattoo_PCT
,count(datacenter_id) dc_id_derived_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(datacenter_id)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  datacenter_id_derived_PCT
,count(system_id) p_fisma_id_tattoo_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(system_id)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  primary_fisma_id_tattoo_PCT
,count(system_id) p_fisma_id_derived_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(system_id)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  primary_fisma_id_derived_PCT
,count(motherboard) motherboard_sn_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(motherboard)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  motherboard_sn_PCT
,count(bigfix_asset_id) bigfix_asset_id_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(bigfix_asset_id)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  bigfix_asset_id_PCT
,count(bios_guid) bios_guid_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(bios_guid)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  bios_guid_PCT
,count(os_cpe) os_cpe_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(os_cpe)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  os_cpe_PCT
from core.VW_ASSETHIST a
where a.devicetype in (select devicetype from core.DEVICETYPES dv where dv.devicetype in ('Server', 'Workstation', 'Computer','Laptop'))
Group by System_Id, datacenter_id, a.report_id) tatoo on tatoo.System_Id = ah.System_Id
and tatoo.datacenter_id = ah.datacenter_id and tatoo.report_id = snap.report_id
left join (select a.System_Id, a.datacenter_id, ac.report_id
,count(fqdn) fqdn_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(fqdn)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  fqdn_PCT
,count(hostname) hostname_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(hostname)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  hostname_PCT
,count(MACADDRESS) Mac_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(MACADDRESS)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  Mac_PCT
,count(ipv4) ipv4_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(ipv4)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  ipv4_PCT
,count(ipv6) ipv6_count
,case when count(a.dw_asset_id) != 0 then
ROUND(count(ipv6)*100.0/sum(count(a.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  ipv6_PCT
from core.AssetInterfaceCoalescedHist ac
join core.Asset a on a.dw_asset_id = ac.dw_asset_id group by a.System_Id, datacenter_id, ac.report_id
) aic on aic.System_Id = ah.System_Id and aic.datacenter_id = ah.datacenter_id
and aic.report_id = snap.report_id

--added to limit the count to Windows OS 1/13/2024
left join (select aah.System_Id, aah.datacenter_id, aah.report_id,count(NETBIOSNAME) netbios_hn_count
,case when count(aah.dw_asset_id) != 0 then
ROUND(count(NETBIOSNAME)*100.0/sum(count(aah.dw_asset_id)) OVER(PARTITION BY datacenter_id,System_Id, report_id),1) 
else null end as  netbios_hn_PCT
from core.VW_ASSETHIST aah
where aah.os is not null and aah.os like '%Windows%'
group by System_Id, datacenter_id, aah.report_id
) netbios on netbios.System_Id = ah.System_Id
and netbios.datacenter_id  = ah.datacenter_id and netbios.report_id = snap.report_id
/***********************/

left join (select aah.System_Id, aah.datacenter_id, aah.report_id, count(os) os_count, sum(count(os)) over(PARTITION BY aah.datacenter_id,aah.System_Id, aah.report_id) total_os
,ROUND(count(os)*100.0/sum(count(dw_asset_id)) over(PARTITION BY aah.datacenter_id,aah.System_Id, aah.report_id),1) as  os_PCT
from core.VW_ASSETHIST aah
where aah.os is not null
group by System_Id, datacenter_id, aah.report_id
) os on os.System_Id = ah.System_Id
and os.datacenter_id  = ah.datacenter_id and os.report_id = snap.report_id
left join (select ah.System_Id, ah.datacenter_id, report_id,
CASE when count(ah.dw_asset_id) > 1 then
count(case when DATEDIFF(day, ah.last_confirmed_time, current_date()) < 3 then 1 end)
else null
end as Count_less72Hrs,
CASE when count(ah.dw_asset_id) > 1 then
count(case when DATEDIFF(day, ah.last_confirmed_time, current_date()) > 3 then 1 end) 
else null end as Count_greater72Hrs,
sum(count(ah.dw_asset_id)) over(PARTITION BY ah.datacenter_id,ah.System_Id, report_id) total_asset
from core.VW_ASSETHIST ah
group by System_Id, datacenter_id, ah.report_id
) tl on tl.System_Id = ah.System_Id
and tl.datacenter_id  = ah.datacenter_id and tl.report_id = snap.report_id
left join (
select 
System_Id, datacenter_id, ah.report_id, count(aws_instancestatus) InstanceStatus_count 
,case when count(aws_instancestatus) != 0 then
ROUND(count(aws_instancestatus)*100.0/sum(count(aws_instancestatus)) over(PARTITION BY datacenter_id, System_Id, ah.report_id),1) 
else null end as InstanceStatus_PCT
from core.VW_ASSETHIST ah
--join Snapshots snap on snap.report_id = ah.report_id
where source_tool_hwam = 'AWS HWAM'
group by System_Id, datacenter_id, ah.report_id
)IStat on IStat.System_Id = ah.System_Id and IStat.datacenter_id  = ah.datacenter_id and IStat.report_id = snap.report_id
right outer join (select System_Id, Acronym,Component_Acronym,Is_DataCenter,Is_MarketPlace,HVAStatus,MEFStatus,
	Group_Acronym,TLC_Phase, Is_ExcludeFromReporting,
	--cast(substring(AWS_accountIds,1,2000) as varchar(2000)) as AWS_accountIds CR #1044
    from CORE.VW_SYSTEMS 
	where Is_PhantomSystem=0 and Is_ExcludeFromReporting =0) S ON S.System_Id = ah.System_Id --and Is_ExcludeFromReporting = 0
left join (select System_Id, Acronym, AWS_accountIds from CORE.VW_SYSTEMS) data_center ON data_center.System_Id = ah.datacenter_id
where ah.System_Id is not null;