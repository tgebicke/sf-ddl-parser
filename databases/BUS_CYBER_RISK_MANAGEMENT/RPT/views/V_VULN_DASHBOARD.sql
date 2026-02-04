create or replace view V_VULN_DASHBOARD(
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
CTE_ReportIDs as (
    SELECT top 1 REPORT_ID, REPORT_DATE, 'MTD' as MTDvsEOM FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0))
    UNION ALL
    SELECT top 1 REPORT_ID, REPORT_DATE, 'EOM' as MTDvsEOM FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1))    
),
Poam as (
    SELECT SYSTEM_ID,POAM_ID,Overall_Status,CVE
    FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) r
    JOIN CORE.VW_POAMHIST ph on ph.REPORT_ID = r.REPORT_ID AND CVE IS NOT NULL
)
select
'1' as filter
,v.SYSTEM_ID as FK_PRIMARY_FISMA_ID
,v.DATACENTER_ID as FK_DATACENTER_ID
,v.id
,v.DW_VUL_ID as FK_dw_vul_number
,v.cve
,v.daysSinceDiscovery
,v.exploitavailable
,v.firstseen
,v.fismaseverity
,v.lastfound
,v.mitigationstatus
,r.REPORT_ID as fk_snapshotid
,s.Acronym
,substring(dc.Acronym, 1, 1) || '***' as Acr_Alias
,s.Component_Acronym
,s.Is_DataCenter
,s.Is_MarketPlace
,s.tlc_phase
,a.Is_Scannable
,v.BODDueDate
,v.FIRSTSEEN as datecreated
,v.datemitigated
,s.HVAStatus
,s.MEFStatus
,dc.acronym as data_center_name
,NULL as DeletionReason
,pluginID as fk_pluginID
,p.solution
,p.familyname
,p.signature
,case when v.IS_BOD = 1 then 'Yes' else 'No' end as is_bod
,dense_rank()over(order by r.REPORT_ID desc) as rankk
,CURRENT_TIMESTAMP() as refresh_date
,(SELECT top 1 report_date::DATE FROM (SELECT top 1 Report_ID,Report_Date FROM CORE.REPORT_IDS where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) CurrentMTDStart
,(SELECT top 1 report_date::DATE FROM (SELECT top 2 Report_ID,Report_Date FROM CORE.REPORT_IDS where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) PrevEOMStart
,v.DW_ASSET_ID as FK_AssetID
,a.computer_type
,a.os
,a.bios_guid
,NULL as source_tool
,a.environment
,a.asset_id_tattoo
,a.os_version
,a.TenableUUID
,a.DeviceType
,r.MTDvsEOM
,s.OATO_Category
,v.CVSSV2BASESCORE as cvss2basescore
,v.CVSSV3BASESCORE as cvss3basescore
,a.VulnRiskTolerance as VRT
,pom.POAM_ID as "POA&M ID"
,pom.Overall_Status
from CTE_ReportIDs r
JOIN CORE.VW_VULHIST v on v.REPORT_ID = r.REPORT_ID
left outer JOIN CORE.Asset a on a.dw_Asset_ID = v.dw_Asset_ID
right outer join CORE.VW_SYSTEMS s ON s.SYSTEM_ID = v.SYSTEM_ID
left outer join CORE.VW_SYSTEMS dc on dc.SYSTEM_ID = v.DATACENTER_ID
left outer join (select DW_VUL_ID,max(PLUGIN_ID) as pluginID FROM CORE.VulPlugin group by DW_VUL_ID) plugs on plugs.DW_VUL_ID = v.DW_VUL_ID
left outer join (select DW_PLUGIN_ID,solution,familyname,PLUGIN_ID,signature from CORE.Plugins) p on p.DW_PLUGIN_ID = plugs.pluginID
left outer join poam pom on pom.SYSTEM_ID = v.SYSTEM_ID;