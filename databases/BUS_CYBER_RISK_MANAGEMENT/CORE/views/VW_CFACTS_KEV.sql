create or replace view VW_CFACTS_KEV(
	CVE,
	DW_VUL_ID,
	PRIMARY_FISMA_ID,
	FIRSTSEEN,
	SIGNATURE,
	SOLUTION,
	DESCRIPTION,
	FISMASEVERITY,
	BODDUEDATE
) COMMENT='No Row'
 as
SELECT bod.CVE as "CVE"
,vm.DW_VUL_ID as dw_vul_id  -- changed vm.ID to vm.DW_VUL_ID
,s.SYSTEM_ID as primary_fisma_id 
,vm.firstSeen
,plugs.signature
,plugs.solution
,plugs.Description
,vm.FISMAseverity
,bod.BODDueDate 
FROM CORE.KEV_CATALOG bod
join CORE.VW_VulMaster vm on vm.cve = bod.CVE
JOIN CORE.VW_Assets a on vm.DW_ASSET_ID = a.DW_ASSET_ID	
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID 
JOIN (select DW_VUL_ID,max(ID) as plugin_ID -- Desc for plugins change over time and create new master records
	FROM CORE.VulPlugin
	group by DW_VUL_ID) vsp  on vsp.DW_VUL_ID = vm.DW_VUL_ID  -- changed vsp.ID to vsp.DW_VUL_ID
JOIN CORE.Plugins plugs on plugs.DW_PLUGIN_ID = vsp.plugin_ID
WHERE  vm.MitigationStatus <> 'fixed' 
and bod.Is_Deleted = 0;