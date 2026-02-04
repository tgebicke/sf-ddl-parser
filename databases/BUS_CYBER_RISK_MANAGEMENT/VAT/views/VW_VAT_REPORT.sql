create or replace view VW_VAT_REPORT(
	FIRSTSEEN,
	LASTFOUND,
	DAYSSINCEDISCOVERY,
	IPV4,
	OS,
	DNSNAME,
	NETBIOSNAME,
	MACADDRESS,
	CVE,
	PLUGIN_ID,
	FAMILYNAME,
	SIGNATURE,
	DESCRIPTION,
	CVSSV2BASESCORE,
	CVSSV3BASESCORE,
	FISMASEVERITY,
	SOLUTION,
	MITIGATIONSTATUS,
	EXPLOITAVAILABLE,
	DATACENTER_ID_DERIVED,
	DW_ASSET_ID,
	DW_VUL_ID,
	DATACENTERACRONYM,
	DATACENTERCOMMONNAME,
	SYSTEMACRONYM,
	SYSTEMCOMMONNAME,
	PRIMARY_FISMA_ID,
	ASSET_ID_TATTOO
) as
SELECT 
vm.firstSeen	-- Orig VAT name: firstSeen
,vm.lastfound	-- Orig VAT name: last_found
,vm.DaysSinceDiscovery	-- Orig VAT name: Days Since Discovery
,a.IPv4 -- Orig VAT name: ip
,a.OS	-- Orig VAT name: OS
,a.FQDN as dnsName -- Orig VAT name: dnsName
,a.netbiosname -- Orig VAT name: netbiosName
,a.macAddress
,vm.CVE	-- Orig VAT name: CVE
,p.plugin_ID --Vplug.pluginid	-- Orig VAT name: pluginID
,p.FAMILY_NAME as familyName	-- Orig VAT name: Family Name
,p.SOLUTION as signature	-- Orig VAT name: Signature
,p.Description -- Orig VAT name: Description
,vm.cvssV2basescore	-- Orig VAT name: CVSSv2 BASE
,vm.cvssV3basescore	-- Orig VAT name: CVSSv3 BASE
,vm.FISMAseverity	-- Orig VAT name: FISMA Severity
,p.solution	-- Orig VAT name: Solution
,vm.MitigationStatus	-- Orig VAT name: state
,vm.exploitAvailable	-- Orig VAT name: Exploit Available
,dc.SYSTEM_ID as datacenter_id_derived	-- Orig VAT name: datacenter_id_derived
,a.DW_ASSET_ID -- NEW Charles Rush approved this for research into issues
,vm.dw_vul_id -- NEW Charles Rush approved this for research into issues
,dc.Acronym as DatacenterAcronym -- 220329 1518
,dc.CommonName as DatacenterCommonName -- 220622 1640 new alias; 220329 1518
,s.Acronym as SystemAcronym -- 220913 1106 CR545
,s.CommonName as SystemCommonName -- 220913 1106 CR545
,s.SYSTEM_ID as primary_fisma_id -- 220913 1106 CR545
,a.asset_id_tattoo -- 220913 1106 CR545
from CORE.VW_VulMaster vm
JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID -- 220622 1640

left outer join (select DW_VUL_ID,max(ID) as MAX_VULPLUGIN_ID FROM CORE.VULPLUGIN group by DW_VUL_ID) plugs on plugs.DW_VUL_ID = vm.dw_vul_id -- 230818
left outer join CORE.VULPLUGIN p on p.ID = plugs.MAX_VULPLUGIN_ID -- 230818

-- 230818 JOIN (select DW_VUL_ID,max(DW_PLUGIN_ID) as plugin_ID -- Desc for plugins change over time and create new master records
-- 230818	FROM CORE.VulPlugin
-- 230818	group by DW_VUL_ID) vsp  on vsp.DW_VUL_ID = vm.DW_VUL_ID
-- 230818 JOIN CORE.Plugins plugs on plugs.DW_PLUGIN_ID = vsp.plugin_ID

WHERE cast(cvssV2basescore as real) >= 7.0 -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL
and vm.MitigationStatus <> 'fixed';