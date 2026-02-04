create or replace view VW_QUARTERLY_FISMA_REPORT_VUL(
	DATACENTER,
	SYSTEM,
	ASSET_ID_TATTOO,
	FQDN,
	NETBIOSNAME,
	CVE,
	EXPLOITAVAILABLE,
	FISMASEVERITY,
	MITIGATIONSTATUS,
	CVSSV2BASESCORE,
	CVSSV3BASESCORE,
	INSERT_DATE,
	FIRSTSEEN,
	LASTFOUND,
	DAYSSINCEDISCOVERY,
	DW_ASSET_ID,
	DW_VUL_ID
) COMMENT='Shows all fixed vulnerabilities detail.'
 as
SELECT -- top 1000000 231027 Not needed in SnowFlake. It was necessary in SQL Server when doing sorts
dc.Acronym as DataCenter
,s.Acronym as System
,a.asset_id_tattoo
,aic.fqdn
,aic.netbiosname
,vm.cve
,vm.exploitAvailable
,vm.FISMAseverity
,vm.MitigationStatus
,vm.CVSSV2BASESCORE
,vm.CVSSV3BASESCORE
,vm.INSERT_DATE
,vm.firstSeen
,vm.lastfound
,vm.DaysSinceDiscovery
,a.DW_ASSET_ID
,vm.dw_vul_id
FROM CORE.VW_Assets a
JOIN CORE.AssetInterfaceCoalesced aic on aic.DW_ASSET_ID = a.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
where lower(vm.MitigationStatus) <> 'fixed' -- and a.Is_Applicable = 1 and vm.DeletionReason IS NULL  
order by dc.Acronym
,s.Acronym
,a.DW_ASSET_ID 
,vm.cve;