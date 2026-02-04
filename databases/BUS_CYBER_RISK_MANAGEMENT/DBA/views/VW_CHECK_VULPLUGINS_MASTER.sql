create or replace view VW_CHECK_VULPLUGINS_MASTER(
	DATACATEGORY,
	DW_ASSET_ID,
	PLUGIN_ID,
	VPM_CVE,
	VPM_LASTFOUND,
	VPM_DELETIONREASON,
	VPM_MITITGATIONSTATUS,
	VM_MITITGATIONSTATUS,
	TOTAL_PLUGIN_COUNT,
	OPEN_PLUGIN_COUNT,
	DELETED_PLUGIN_COUNT,
	FIXED_PLUGIN_COUNT,
	DELETIONREASON,
	EXTENDED_MITIGATIONSTATUS,
	PRIORTOCHANGE_MITITGATIONSTATUS
) COMMENT='Check VULPLUGINS_MASTER\t'
 as
SELECT DISTINCT raw.datacategory,vpm.dw_asset_id,vpm.plugin_id,vpm.VPM_CVE,vpm.LASTFOUND as VPM_LASTFOUND,vpm.deletionreason as VPM_DELETIONREASON,vpm.mitigationstatus as VPM_MITITGATIONSTATUS,vm.mitigationstatus as VM_MITITGATIONSTATUS
,vm.total_plugin_count,vm.open_plugin_count,vm.deleted_plugin_count,vm.fixed_plugin_count,vm.deletionreason,vm.extended_mitigationstatus,b.mitigationstatus as PriorToChange_MITITGATIONSTATUS
from (SELECT f.value::string as VPM_CVE,vp.* exclude CVE
    FROM CORE.VULPLUGINS_MASTER vp
    join table(flatten(cve,outer=>true)) as f) vpm --on vpm.DW_ASSET_ID = vm.DW_ASSET_ID and t.VP_CVE = vm.CVE

left outer join (SELECT snap.datacategory,r.dw_asset_id,f.value::string as RAW_CVE,r.plugin_id
    FROM CORE.RAW_TENABLE_VUL r
    join CORE.SNAPSHOT_IDS snap on snap.snapshot_id = r.snapshot_id
    join table(flatten(cve,outer=>true)) as f
    where upper(snap.datacategory) like '%MIT%') raw on raw.DW_ASSET_ID = vpm.DW_ASSET_ID and raw.RAW_CVE = vpm.VPM_CVE and raw.plugin_id = vpm.plugin_id

left outer join CORE.VULMASTER vm on vm.dw_asset_id = vpm.DW_ASSET_ID and vm.cve = vpm.VPM_CVE

left outer join SANDBOX.BACKUP_VULMASTER_240119_2342 b on b.dw_asset_id = vpm.DW_ASSET_ID and b.cve = vpm.VPM_CVE
;