create or replace view V_BOD_DETAIL(
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
	FISMA_ID,
	IS_MARKETPLACE,
	ASSET_ID_TATTOO,
	FQDN,
	HOSTNAME,
	CVE,
	"Vendor/Project",
	PRODUCT,
	VULNERABILITYNAME,
	DATEADDEDTOCATALOG,
	SHORTDESCRIPTION,
	BODDUEDATE,
	DAYSSINCEDISCOVERY,
	EXPLOITAVAILABLE,
	FISMASEVERITY
) WITH ROW ACCESS POLICY ACCESS_CONTROL.SECURITY.CRM_RPT_FISMA_POLICY ON (FISMA_ID)
 COMMENT='Contains previous days details related to the KEV Vuln data population '
 as
SELECT a.DATACENTER_ACRONYM
,a.SYSTEM_ACRONYM
,a.system_id FISMA_ID
,s.IS_MARKETPLACE
,a.asset_id_tattoo
,a.fqdn
,a.hostname
,vm.CVE
,kev.VendorProject as "Vendor/Project"
,kev.Product
,kev.VulnerabilityName
,kev.DateAddedToCatalog
,kev.ShortDescription
,kev.BODDueDate
,vm.DaysSinceDiscovery
,kev.exploitAvailable
,kev.FISMAseverity
FROM CORE.VW_VulMaster vm
join CORE.VW_Assets a on a.dw_asset_id = vm.DW_ASSET_ID
join core.vw_systems s on a.system_id = s.system_id
JOIN CORE.KEV_CATALOG kev on kev.CVE = vm.cve and kev.Is_Deleted = 0
where vm.MitigationStatus <> 'fixed'
;