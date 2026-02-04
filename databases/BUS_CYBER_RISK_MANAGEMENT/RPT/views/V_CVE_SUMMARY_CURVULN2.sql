create or replace view V_CVE_SUMMARY_CURVULN2(
	"pluginID",
	"signature",
	"Solution",
	"FK_dw_vul_number",
	"cve",
	"CVSSv2Base",
	"CVSSv3Base",
	"MitigationStatus",
	"SystemAcronym",
	"DaysSinceDiscovery",
	"ip",
	"macAddress",
	"dnsName",
	"netbiosname"
) COMMENT='open and reopened for HVA'
 as 
select
plugs.plugin_ID as "pluginID"
,null as "signature"
,null as "Solution"
,vm.DW_VUL_ID as "FK_dw_vul_number"
,vm.CVE as "cve"
,vm.CVSSV2BASESCORE as "CVSSv2Base"
,vm.CVSSV3BASESCORE as "CVSSv3Base"
,vm.MITIGATIONSTATUS as "MitigationStatus"
,s.ACRONYM as "SystemAcronym"
,vm.DAYSSINCEDISCOVERY as "DaysSinceDiscovery"
,a.IPV4 as "ip"
,a.MACADDRESS as "macAddress"
,a.FQDN as "dnsName"
,a.NETBIOSNAME as "netbiosname"
from CORE.VW_ASSETS a
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = a.SYSTEM_ID
JOIN CORE.VW_VULMASTER vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
LEFT OUTER JOIN CORE.VulPlugin plugs on plugs.DW_VUL_ID = vm.DW_VUL_ID
where upper(s.TLC_PHASE) = 'OPERATE' AND HVAStatus='Yes' AND MitigationStatus IN ('open','reopened') 
;