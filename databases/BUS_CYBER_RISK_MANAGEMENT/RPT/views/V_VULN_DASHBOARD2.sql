create or replace view V_VULN_DASHBOARD2(
	V_ACR,
	V_COMP_ACR,
	V_TLC_PHASE,
	V_HVA_STAT,
	V_IS_MRKT_PLC,
	V_MEF_STATUS,
	V_ACR_DISPLAY,
	FILTER,
	FK_PRIMARY_FISMA_ID,
	FK_DATACENTER_ID,
	ID,
	FK_DW_VUL_NUMBER,
	CVE,
	DAYSSINCEDISCOVERY,
	EXPLOITAVAILABLE,
	FIRSTSEEN,
	FISMASEVERITY,
	LASTFOUND,
	MITIGATIONSTATUS,
	SNAPSHOTID,
	ACRONYM,
	ACR_ALIAS,
	COMPONENT_ACRONYM,
	IS_DATACENTER,
	IS_MARKETPLACE,
	TLC_PHASE,
	IS_SCANNABLE,
	BODDUEDATE,
	DATECREATED,
	DATEMITIGATED,
	HVASTATUS,
	MEFSTATUS,
	DATA_CENTER_NAME,
	DELETIONREASON,
	FK_PLUGINID,
	SOLUTION,
	FAMILYNAME,
	SIGNATURE,
	IS_BOD,
	RANKK,
	REFRESH_DATE,
	CURRENTMTDSTART,
	PREVEOMSTART,
	FK_ASSETID,
	COMPUTER_TYPE,
	OS,
	BIOS_GUID,
	SOURCE_TOOL,
	ENVIRONMENT,
	ASSET_ID_TATTOO,
	OS_VERSION,
	TENABLEUUID,
	DEVICETYPE,
	MTDVSEOM,
	OATO_CATEGORY,
	CVSS2BASESCORE,
	CVSS3BASESCORE,
	VRT,
	"POA&M ID",
	OVERALL_STATUS
) COMMENT='Not using in tableau'
 as
with
ReportIDs as ((select Report_ID,Report_Date, snapshot_ID, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date,Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where DataCategory= 'VUL')a where rankkForSnap =1
	union all
	select Report_ID,Report_Date, snapshot_ID, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date, Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where Is_endOfMonth =1 and DataCategory= 'VUL')a where rankkForSnap = 1)),
Snapshots as (select Report_ID, snapshot_ID,
	case when dense_rank()over(order by Report_ID desc) =1 then 'MTD' when dense_rank()over(order by Report_ID desc) =2 then 'EOM' end as MTDvsEOM
	from ReportIDs r)

select  v.Acronym as v_acr,v.Component_Acronym as v_comp_acr ,v.TLC_Phase v_tlc_phase,v.HVAStatus as v_hva_stat,v.Is_MarketPlace as v_is_mrkt_plc,v.MEFStatus as v_mef_status,
case when vuln.acronym is null then concat(v.Acronym,'*') else v.Acronym end as v_acr_display,
vuln.* from CORE.VW_SYSTEMS v
left outer join
(
select
'1' as filter
,v.SYSTEM_ID as FK_PRIMARY_FISMA_ID
,v.DATACENTER_ID as FK_DATACENTER_ID
,v.id
,v.ID as FK_dw_vul_number
,v.cve
,daysSinceDiscovery
,exploitavailable
,firstseen
,fismaseverity
,lastfound
,mitigationstatus
,snap.snapshot_id as snapshotid
,dc.Acronym
,substring(dc.Acronym, 1, 1) || '***' as Acr_Alias
,dc.Component_Acronym
,dc.Is_DataCenter
,dc.Is_MarketPlace
,tlc_phase
,A.Is_Scannable
,bodcat.BODDueDate
,vm.dateCreated as datecreated
,vm.datemitigated
,dc.HVAStatus
,dc.MEFStatus
,data_center.acronym as data_center_name
,vm.DeletionReason
,p.dw_plugin_ID as fk_pluginID
,p.solution
,p.familyname
,p.signature
,case when bodcat.Is_Deleted = 0 then 'Yes' else 'No' end as is_bod
,dense_rank()over(order by SNAPSHOTID desc) as rankk
,CURRENT_TIMESTAMP() as refresh_date
,(SELECT top 1 report_date::DATE FROM (SELECT top 1 Report_ID,Report_Date FROM ReportIDs where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) CurrentMTDStart
,(SELECT top 1 report_date::DATE FROM (SELECT top 2 Report_ID,Report_Date FROM ReportIDs where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) PrevEOMStart
,a.dw_asset_id as FK_AssetID
,A.computer_type
,A.os
,A.bios_guid
,NULL as source_tool
,A.environment
,A.asset_id_tattoo
,A.os_version
,A.TenableUUID
,D.DeviceType
,snap.MTDvsEOM
,dc.OATO_Category
,vm.cvss2basescore
,vm.cvss3basescore
,cast(SUM(IFF(vm.dw_vul_id is null,0,daysSinceDiscovery*cast(vm.cvss2basescore as float)* dc.OATO_Category*IFF(exploitAvailable='Yes',2,1)))/IFF(count(1)=0,1,count(1)) as decimal(10,2)) as VRT
,pom.POAM_ID as "POA&M ID"
,pom.Overall_Status
from CORE.VW_VULHIST v 
join CORE.reportsnapshots RC on v.report_id = RC.REPORT_ID
JOIN SnapShots snap on RC.Snapshot_ID = snap.snapshot_ID
left outer JOIN CORE.Asset A ON V.DW_Asset_ID = A.DW_Asset_ID
left outer JOIN CORE.DeviceTypes D ON a.DeviceType=D.DeviceType
left outer join (select SYSTEM_ID,Acronym,Component_Acronym,Is_DataCenter,Is_MarketPlace,HVAStatus,MEFStatus,TLC_Phase,OATO_Category from CORE.VW_Systems) DC ON DC.SYSTEM_ID = V.SYSTEM_ID
LEFT JOIN (select cve,bodDueDate,Is_Deleted from CORE.KEV_Catalog) bodcat  on bodcat.CVE = V.cve
left join (select dw_vul_id,datemitigated,DeletionReason,firstseen as datecreated,  CVSSV2BASESCORE as cvss2basescore, CVSSV3BASESCORE as cvss3basescore from CORE.VulMaster)vm on vm.dw_vul_id = v.dw_vul_id
left outer join (select SYSTEM_ID,Acronym from CORE.VW_Systems) data_center ON data_center.SYSTEM_ID = V.datacenter_id
left outer join (select dw_vul_id,max(PLUGIN_ID)  as pluginID FROM CORE.VulPlugin vp group by dw_vul_id) plugs on (plugs.dw_vul_id = vm.dw_vul_id)
left outer join (select DW_PLUGIN_ID,solution,familyname,plugin_id,signature from CORE.Plugins) p on (p.DW_PLUGIN_ID = plugs.pluginID)
left outer join (SELECT System_ID,POAM_ID,Overall_Status FROM CORE.POAMHist
                 where Report_ID = (select Report_ID from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date, Snapshot_ID from CORE.VW_ReportSnapshots 
                                    where DataCategory= 'CFACTS')a where rankkForSnap =1)
                ) pom on pom.System_ID=v.System_ID
where MitigationStatus in ('open', 'repoened') or (MitigationStatus = 'FIXED' and vm.datemitigated > (current_date() - 60))
group by
FK_PRIMARY_FISMA_ID
,FK_DATACENTER_ID
,v.id
,FK_dw_vul_number
,v.cve
,daysSinceDiscovery
,exploitavailable
,firstseen
,fismaseverity
,lastfound
,mitigationstatus
,snapshotid
,dc.Acronym
,Acr_Alias
,dc.Component_Acronym
,dc.Is_DataCenter
,dc.Is_MarketPlace
,tlc_phase
,A.Is_Scannable
,bodcat.BODDueDate
,datecreated
,vm.datemitigated
,dc.HVAStatus
,dc.MEFStatus
,data_center_name
,vm.DeletionReason
,fk_pluginID
,p.solution
,p.familyname
,p.signature
,bodcat.Is_Deleted 
,FK_AssetID
,A.computer_type
,A.os
,A.bios_guid
,source_tool
,A.environment
,A.asset_id_tattoo
,A.os_version
,A.TenableUUID
,D.DeviceType
,snap.MTDvsEOM
,dc.OATO_Category
,vm.cvss2basescore
,vm.cvss3basescore
,"POA&M ID"
,pom.Overall_Status
) vuln on vuln.acronym = v.Acronym and vuln.Component_Acronym = v.Component_Acronym 
where v.Component_Acronym not in ('Not specified','FCHCO','CMCHO');