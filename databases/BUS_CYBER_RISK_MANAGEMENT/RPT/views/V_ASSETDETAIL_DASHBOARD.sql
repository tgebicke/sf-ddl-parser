create or replace view V_ASSETDETAIL_DASHBOARD(
	"filter",
	FK_PRIMARY_FISMA_ID,
	FK_DATACENTER_ID,
	"id",
	"FK_dw_vul_number",
	"cve",
	"daysSinceDiscovery",
	"exploitavailable",
	"firstseen",
	"fismaseverity",
	"lastfound",
	"mitigationstatus",
	"fk_snapshotid",
	"BODDueDate",
	"datecreated",
	"datemitigated",
	"DeletionReason",
	"Acronym",
	"Acr_Alias",
	"Component_Acronym",
	"is_bod",
	"rankk",
	"refresh_date",
	"solution",
	"familyname",
	"HVAStatus",
	"MEFStatus",
	"Is_MarketPlace",
	"signature",
	"pluginid",
	"data_center_name",
	"FK_AssetID",
	"computer_type",
	"os",
	"bios_guid",
	"source_tool",
	"environment",
	"asset_id_tattoo",
	"os_version",
	"TenableUUID",
	"DeviceType",
	"fqdn",
	"hostname",
	"ipv4",
	"ipv6",
	"Mac",
	"netbiosname",
	"VulnRiskTolerance",
	"cvss2basescore",
	"OATO_Category",
	"Sensor_firstseen",
	"Sensor_lastfound",
	"cvss3basescore",
	"dw_asset_id",
	"datacenter_id_derived",
	"AWS_accountIds",
	"TLC_Phase",
	CLOUD_ACCOUNT_ID
) COMMENT='Not using in tableau'
 as
--with 
--ReportIDs as ((select REPORT_ID,REPORT_DATE,SNAPSHOT_ID 
--    from (select rank()over(partition by DataCategory order by REPORT_DATE desc) rankkForSnap,REPORT_ID,REPORT_DATE,SNAPSHOT_ID from CORE.VW_ReportSnapshots
--	where DataCategory= 'VUL')a where rankkForSnap =1)),
--AssetSnapshots as (select REPORT_ID,SNAPSHOT_ID from ReportIDs r)
select 1 as filter,
s.SYSTEM_ID as FK_PRIMARY_FISMA_ID,
dc.SYSTEM_ID as FK_DATACENTER_ID,
vm.DW_VUL_ID as id,
vm.DW_VUL_ID as FK_DW_VUL_NUMBER,
vm.cve,
vm.daysSinceDiscovery,
vm.exploitavailable,
vm.firstseen,
vm.fismaseverity,
vm.lastfound,
--vm.cve,
vm.mitigationstatus,
--(select REPORT_ID FROM AssetSnapshots) as FK_SNAPSHOTID,
vm.FK_SNAPSHOTID,
vm.BODDueDate,
vm.insert_date as datecreated,
vm.datemitigated,
null as DELETIONREASON,
s.Acronym,
substring(s.Acronym, 1, 1) || '***' as Acr_Alias,
s.Component_Acronym,
vm.IS_KEV as is_bod,
dense_rank()over(order by FK_SNAPSHOTID ASC) as rankk, -- Reenabled 230622
CURRENT_TIMESTAMP() as refresh_date,
p.solution,
p.FAMILY_NAME as familyname, -- 230818 1433
s.HVAStatus,
s.MEFStatus,
s.Is_MarketPlace,
p.SOLUTION as signature, -- 230818 1433
p.PLUGIN_ID as pluginid,  -- 230818 1433
dc.acronym as data_center_name,
a.dw_Asset_ID as FK_AssetID,
a.computer_type,
a.os,
a.bios_guid,
a.source_tool_lastseen as source_tool,
a.environment,
a.asset_id_tattoo,
a.os_version,
a.TenableUUID,
a.DeviceType,
aic.fqdn,
aic.hostname,
aic.ipv4,
aic.ipv6,
aic.MACADDRESS as Mac,
aic.netbiosname,
a.VulnRiskTolerance,
vm.CVSSV2BASESCORE as cvss2basescore,
s.OATO_Category,
vm.FIRSTSEEN as Sensor_firstseen,
vm.LASTFOUND as Sensor_lastfound,
vm.CVSSV3BASESCORE as cvss3basescore,
vm.dw_asset_id,
dc.SYSTEM_ID as datacenter_id_derived,
SUBSTRING(s.AWS_ACCOUNTIDS,1,2000) as AWS_ACCOUNTIDS, -- 230328 1646 EBF add substring to AWS_accountIds because varchar(max) causes Tableau to fail
s.TLC_Phase,
a.CLOUD_ACCOUNT_ID -- 241125 CR1038
from CORE.VW_ASSETS a
JOIN (select (select REPORT_ID from TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as FK_SNAPSHOTID
,* FROM CORE.VW_VULMASTER) vm on vm.dw_asset_id = a.dw_asset_id

RIGHT OUTER JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = a.SYSTEM_ID
left outer JOIN CORE.VW_SYSTEMS dc on dc.SYSTEM_ID = a.DATACENTER_ID

left outer join (select DW_VUL_ID,max(ID) as MAX_VULPLUGIN_ID FROM CORE.VULPLUGIN group by DW_VUL_ID) plugs on plugs.DW_VUL_ID = vm.dw_vul_id -- 230818 1433
left outer join CORE.VULPLUGIN p on p.ID = plugs.MAX_VULPLUGIN_ID -- 230818 1433
    
-- 230818 1433 left outer join (select dw_vul_id,max(DW_PLUGIN_ID) as pluginID FROM CORE.VulPlugin group by dw_vul_id) plugs on (plugs.dw_vul_id = vm.DW_VUL_ID)
-- 230818 1433 left outer join (select DW_PLUGIN_ID,solution,familyname,DW_PLUGIN_ID as pluginid,signature from CORE.Plugins) p on (p.DW_PLUGIN_ID = plugs.pluginID)

left join (select i.DW_ASSET_ID,i.fqdn,i.hostname,i.ipv4,i.ipv6,i.MacADDRESS,i.netbiosname
    from CORE.ASSETINTERFACECOALESCED i
    JOIN (select DW_ASSET_ID, Max(ID) as AssetInterfaceID
    FROM CORE.ASSETINTERFACECOALESCED group by DW_ASSET_ID) as InterFaceMax ON InterFaceMax.AssetInterfaceID=i.ID) aic on aic.DW_ASSET_ID = a.DW_ASSET_ID
;