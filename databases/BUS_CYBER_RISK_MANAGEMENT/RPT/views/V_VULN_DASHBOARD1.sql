create or replace view V_VULN_DASHBOARD1(
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
	FK_SNAPSHOTID,
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
	from ReportIDs r),
Poam as (
SELECT ID as System_ID,"POA&M ID" as POAM_ID,"Overall_Status" as Overall_Status -- 231027 use ID, "POA&M ID", "Overall_Status"
FROM RPT.V_POAMHist -- 231027 was VW_POAMHist
where "ReportID" = (select Report_ID from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date,Snapshot_ID from CORE.VW_ReportSnapshots
	where DataCategory= 'CFACTS')a where rankkForSnap =1)
)
select
'1' as filter
,v.SYSTEM_ID as FK_PRIMARY_FISMA_ID
,V.DATACENTER_ID as FK_DATACENTER_ID
,v.id
,v.ID as FK_dw_vul_number
,v.cve
,daysSinceDiscovery
,exploitavailable
,firstseen
,fismaseverity
,lastfound
,mitigationstatus
,snap.snapshot_ID as FK_snapshotID
,dc.Acronym
,substring(dc.Acronym, 1, 1) + '***' as Acr_Alias
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
,dense_rank()over(order by snap.snapshot_ID desc) as rankk
,CURRENT_TIMESTAMP() as refresh_date
,(SELECT top 1 report_date::DATE FROM (SELECT top 1 Report_ID,Report_Date FROM ReportIDs where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) CurrentMTDStart
,(SELECT top 1 report_date::DATE FROM (SELECT top 2 Report_ID,Report_Date FROM ReportIDs where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) PrevEOMStart
,a.dw_asset_id as FK_AssetID
,A.computer_type
,A.os
,A.bios_guid
,NULL as source_tool -- where is source_tool?
,A.environment
,A.asset_id_tattoo
,A.os_version
,A.TenableUUID
,A.DeviceType
,snap.MTDvsEOM
,dc.OATO_Category
,vm.cvss2basescore
,vm.cvss3basescore
,a.VulnRiskTolerance VRT
,pom.poam_id as "POA&M ID"
,pom.Overall_Status
from CORE.vw_vulhist v 
join CORE.reportsnapshots RC on v.report_id = RC.REPORT_ID
JOIN SnapShots snap on RC.Snapshot_ID = snap.snapshot_ID
left outer JOIN CORE.VW_Assets A ON V.dw_Asset_ID = A.dw_Asset_ID
right outer join (select ID as SYSTEM_ID,"Acronym" as Acronym,"Component_Acronym" as Component_Acronym,"Is_DataCenter" as Is_DataCenter,"Is_MarketPlace" as Is_MarketPlace,"HVAStatus" as HVAStatus,"MEFStatus" as MEFStatus, "TLC_Phase" as tlc_phase, "OATO_Category" as OATO_Category from rpt.V_Systems) DC ON DC.SYSTEM_ID = V.SYSTEM_ID -- 231017 was VW_Systems
LEFT JOIN (select cve,bodDueDate,Is_Deleted from CORE.KEV_Catalog) bodcat on bodcat.CVE = V.cve
left join (select dw_vul_id,datemitigated,NULL as DeletionReason,FIRSTSEEN as datecreated, CVSSV2BASESCORE as cvss2basescore, CVSSV3BASESCORE as cvss3basescore from CORE.VW_VulMaster) vm on vm.dw_vul_id = v.dw_vul_id
left outer join (select ID as system_id,"Acronym" as acronym from rpt.V_Systems) data_center ON data_center.SYSTEM_ID = V.datacenter_id -- 231017 was VW_Systems
left outer join (select dw_vul_id,max(PLUGIN_ID)  as pluginID FROM CORE.VulPlugin vp group by dw_vul_id) plugs on (plugs.dw_vul_id = vm.dw_vul_id)
left outer join (select DW_PLUGIN_ID,solution,familyname,plugin_id,signature from CORE.Plugins) p on (p.DW_PLUGIN_ID = plugs.pluginID)
left outer join Poam pom on pom.System_ID=v.System_ID
where lower(MitigationStatus) in ('open', 'repoened') or (lower(MitigationStatus) = 'fixed' and vm.datemitigated > (current_date() - 60));