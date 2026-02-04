create or replace view V_VULN_DASHBOARD_SYSTEMVRT(
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
SELECT "FK_SystemID" as System_ID,"POA&M ID" as POAM_ID,"Overall_Status" as Overall_Status
FROM RPT.V_POAMHist
where "ReportID" = (select Report_ID from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date,Snapshot_ID from CORE.VW_ReportSnapshots
	where DataCategory= 'CFACTS')a where rankkForSnap =1)
)
select
'1' as filter
,v.SYSTEM_ID as FK_PRIMARY_FISMA_ID
,v.DATACENTER_ID as FK_DATACENTER_ID
,v.id
,v.ID as FK_dw_vul_number
,v.cve
,v.daysSinceDiscovery
,v.exploitavailable
,vm.firstseen
,v.fismaseverity
,v.lastfound
,v.mitigationstatus
,snap.snapshot_ID as FK_snapshotID
,sys.Acronym
,substring(sys.Acronym, 1, 1) || '***' as Acr_Alias
,sys.Component_Acronym
,sys.Is_DataCenter
,sys.Is_MarketPlace
,tlc_phase
,a.Is_Scannable
,vm.BODDueDate
,vm.FIRSTSEEN as datecreated
,vm.datemitigated
,sys.HVAStatus
,sys.MEFStatus
,dc.acronym as data_center_name
,vm.DeletionReason
,PI.dw_plugin_ID as fk_pluginID
,PI.solution
,PI.familyname
,PI.signature
,case when vm.IS_KEV = 1 then 'Yes' else 'No' end as is_bod
,dense_rank()over(order by snap.snapshot_ID desc) as rankk
,CURRENT_TIMESTAMP() as refresh_date
,(SELECT top 1 report_date::DATE FROM (SELECT top 1 Report_ID,Report_Date FROM ReportIDs where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) CurrentMTDStart
,(SELECT top 1 report_date::DATE FROM (SELECT top 2 Report_ID,Report_Date FROM ReportIDs where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) PrevEOMStart
,a.dw_asset_id as FK_AssetID
,a.computer_type
,a.os
,a.bios_guid
,NULL as source_tool -- where is source_tool?
,a.environment
,a.asset_id_tattoo
,a.os_version
,a.TenableUUID
,a.DeviceType
,snap.MTDvsEOM
,sys.OATO_Category
,vm.cvss2basescore
,vm.cvss3basescore
,ss.VulnRiskTolerance VRT
,pom.poam_id as "POA&M ID"
,pom.Overall_Status
from CORE.VW_VULHIST v 
--join CORE.reportsnapshots RC on v.report_id = RC.REPORT_ID
JOIN SnapShots snap on snap.REPORT_ID = v.REPORT_ID
left outer JOIN CORE.VW_Assets a ON V.dw_Asset_ID = a.dw_Asset_ID

right outer join (select SYSTEM_ID,Acronym,Component_Acronym,Is_DataCenter,Is_MarketPlace,HVAStatus,MEFStatus, tlc_phase, OATO_Category from CORE.VW_Systems) sys ON sys.SYSTEM_ID = V.SYSTEM_ID
-- 240222 CR840 chg from table SYSTEMSUMMARY to view VW_SYSTEMSUMMARY
LEFT JOIN (select SYSTEM_ID, VulnRiskTolerance from CORE.VW_SYSTEMSUMMARY where REPORT_ID = (select max(REPORT_ID) from ReportIDs)) SS ON SS.System_ID = sys.System_ID

--LEFT JOIN (select cve,bodDueDate,Is_Deleted from CORE.KEV_Catalog) bodcat on bodcat.CVE = V.cve
left join (select BODDUEDATE,dw_vul_id,datemitigated,NULL as DeletionReason,FIRSTSEEN, CVSSV2BASESCORE as cvss2basescore, CVSSV3BASESCORE as cvss3basescore, IS_KEV from CORE.VW_VulMaster) vm on vm.dw_vul_id = v.dw_vul_id
left outer join (select system_id,acronym from CORE.VW_Systems) dc ON dc.SYSTEM_ID = V.datacenter_id

left outer join (select dw_vul_id,max(PLUGIN_ID) as pluginID FROM CORE.VulPlugin vp group by dw_vul_id) plugs on (plugs.dw_vul_id = vm.dw_vul_id)
left outer join (select DW_PLUGIN_ID,solution,familyname,plugin_id,signature from CORE.Plugins) PI on (PI.DW_PLUGIN_ID = plugs.pluginID)
left outer join Poam pom on pom.System_ID = v.System_ID;