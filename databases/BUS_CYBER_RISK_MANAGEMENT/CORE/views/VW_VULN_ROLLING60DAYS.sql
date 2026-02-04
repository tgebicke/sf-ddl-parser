create or replace view VW_VULN_ROLLING60DAYS(
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
	FAMILY_NAME,
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
	CVSSV2BASESCORE,
	CVSSV3BASESCORE,
	VRT,
	POAM_ID,
	OVERALL_STATUS
) COMMENT='Used to populate RPT.Temp_Vuln_FV_Rolling60Days from within CORE.SP_CRM_WRITE_REPORTINGTABLES'
 as
--
-- V5 replace Snapshots CTE and POAMHIST REPORT_ID (using FN_CRM_GET_REPORT_ID(0)) and mitigation filter at bottom not at join
--
--
-- The only difference between rpt.v_systems and core.rpt.wv_systems is alias names
--
with
Snapshots as (
    select 1 as RANKK, REPORT_ID, 'MTD' as MTDVSEOM from table(CORE.FN_CRM_GET_REPORT_ID(0))
    UNION ALL
    select 2 as RANKK, REPORT_ID, 'EOM' as MTDVSEOM from table(CORE.FN_CRM_GET_REPORT_ID(1))
)
select sys.ACRONYM as v_acr,sys.COMPONENT_ACRONYM as v_comp_acr ,sys.TLC_Phase v_tlc_phase,sys.HVAStatus as v_hva_stat,sys.IS_MARKETPLACE as v_is_mrkt_plc,sys.MEFSTATUS as v_mef_status,
case when vuln.ACRONYM is null then concat(sys.ACRONYM,'*') else sys.ACRONYM end as v_acr_display,
vuln.* from CORE.VW_SYSTEMS sys

left outer join
(
select
'1' as filter
,vh.SYSTEM_ID as FK_PRIMARY_FISMA_ID
,vh.DATACENTER_ID as FK_DATACENTER_ID
,vh.id
,vh.DW_VUL_ID as FK_dw_vul_number
,vh.cve
,vh.daysSinceDiscovery
,vh.exploitavailable
,vh.firstseen
,vh.fismaseverity
,vh.lastfound
,vh.mitigationstatus
,vh.REPORT_ID as fk_snapshotid
,s.ACRONYM
,substring(s.ACRONYM, 1, 1) || '***' as Acr_Alias -- 231103 changed from + to ||
,s.COMPONENT_ACRONYM
,s.IS_DATACENTER
,s.IS_MARKETPLACE
,s.TLC_PHASE
,A.Is_Scannable
--,vh.cvss2basescore
,bodcat.BODDueDate
,vm.insert_date as datecreated
,vm.datemitigated
,s.HVASTATUS
,s.MEFSTATUS
,data_center.ACRONYM as data_center_name
,vm.DeletionReason
,p.ID as fk_pluginID
,p.solution
,p.family_name
,p.synopsis as signature
,case when bodcat.Is_Deleted = 0 then 'Yes' else 'No' end as is_bod
--,dense_rank()over(order by vh.REPORT_ID desc) as rankk -- 231201
,snap.RANKK as rankk
,CURRENT_TIMESTAMP as refresh_date
,(SELECT top 1 report_date::DATE FROM (SELECT top 1 Report_ID,Report_Date FROM CORE.REPORT_IDS where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) CurrentMTDStart
,(SELECT top 1 report_date::DATE FROM (SELECT top 2 Report_ID,Report_Date FROM CORE.REPORT_IDS where Is_endOfMonth=1 order by Report_ID desc) r order by Report_ID asc) PrevEOMStart
--,(SELECT top (1) convert(date,reportdate) FROM (SELECT top (1) ID,ReportDate FROM CORE.REPORT_IDS where Is_endOfMonth=1 order by ID desc) r order by ID asc) CurrentMTDStart
--,(SELECT top (1) convert(date,reportdate) FROM (SELECT top (2) ID,ReportDate FROM CORE.REPORT_IDS where Is_endOfMonth=1 order by ID desc) r order by ID asc) PrevEOMStart
,vh.DW_ASSET_ID as FK_AssetID
,A.computer_type
,A.os
,A.bios_guid
,A.source_tool_lastseen as source_tool
,A.environment
,A.asset_id_tattoo
,A.os_version
,A.TenableUUID
,D.DeviceType
,snap.MTDvsEOM
,s.OATO_CATEGORY
,vm.cvssv2basescore
,vm.cvssv3basescore
,a.VulnRiskTolerance VRT
,pom.POAM_ID
,pom.Overall_Status
from CORE.VulMaster vm 
left join CORE.VW_VULHIST_UNFILTERED vh on vm.DW_VUL_ID = vh.DW_VUL_ID
JOIN SnapShots snap on vh.REPORT_ID = snap.REPORT_ID
--and (vm.MitigationStatus in ('open', 'reopened') or (vm.MitigationStatus = 'fixed' and vm.datemitigated > (current_date() - 60)))
left outer JOIN CORE.Asset A ON vh.DW_ASSET_ID = A.DW_ASSET_ID  and A.is_applicable=1
left outer JOIN CORE.DeviceTypes D ON a.DeviceType=D.DEVICETYPE
left outer join CORE.VW_SYSTEMS data_center ON data_center.SYSTEM_ID = vh.datacenter_id
left outer JOIN CORE.VW_SYSTEMS s ON s.SYSTEM_ID = vh.SYSTEM_ID
LEFT JOIN (select cve,bodDueDate,Is_Deleted from CORE.KEV_CATALOG ) bodcat on bodcat.CVE = vh.cve

left outer join (select DW_VUL_ID,max(ID) as MAX_VULPLUGIN_ID FROM CORE.VulPlugin vp group by DW_VUL_ID) plugs on (plugs.DW_VUL_ID = vm.DW_VUL_ID)
left outer join CORE.VULPLUGIN p on p.ID = plugs.MAX_VULPLUGIN_ID
--left outer join (select id,solution,familyname,pluginid,signature from CORE.Plugins ) p on (p.ID = plugs.fk_pluginID)
left outer join (SELECT p.SYSTEM_ID,p.POAM_ID,CVE,p.Overall_Status
    FROM table(CORE.FN_CRM_GET_REPORT_ID(0)) r
    JOIN CORE.POAMHist p on p.REPORT_ID = r.REPORT_ID
    where p.CVE IS NOT NULL) pom on pom.CVE=vh.CVE and pom.SYSTEM_ID=vh.SYSTEM_ID
    
where (vm.MitigationStatus in ('open', 'reopened') or (vm.MitigationStatus = 'fixed' and vm.datemitigated > (current_date() - 60)))
) vuln on vuln.FK_PRIMARY_FISMA_ID = sys.SYSTEM_ID   -- 231103 (vuln."Acronym" = vh."Acronym" and vuln."Component_Acronym" = vh."Component_Acronym" )

where sys.COMPONENT_ACRONYM not in ('Not specified','FCHCO','CMCHO') -- 231103 and "Is_ExcludeFromReporting" = 0
;