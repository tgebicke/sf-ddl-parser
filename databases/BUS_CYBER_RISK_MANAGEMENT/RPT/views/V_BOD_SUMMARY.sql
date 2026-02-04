create or replace view V_BOD_SUMMARY(
	DATACENTER,
	FISMA_ID,
	SYSTEM_ACRONYM,
	ACR_ALIAS,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	IS_MARKETPLACE,
	CVE,
	"Vendor/Project",
	PRODUCT,
	VULNERABILITYNAME,
	DATEADDEDTOCATALOG,
	SHORTDESCRIPTION,
	BODDUEDATE,
	EXPLOITAVAILABLE,
	FISMASEVERITY,
	"POA&M ID",
	TOTAL,
	OVERALL_STATUS
) WITH ROW ACCESS POLICY ACCESS_CONTROL.SECURITY.CRM_RPT_FISMA_POLICY ON (FISMA_ID)
 COMMENT='Contains previous days Summary level data related to the Known & exploited Vuln population'
 as
SELECT 
dc.Acronym as DataCenter
,s.SYSTEM_ID as FISMA_ID
,s.Acronym as System_Acronym
,substring(s.Acronym, 1, 1) || '***' as Acr_Alias
,s.Component_Acronym
,s.Group_Acronym
,s.IS_MARKETPLACE
,vm.CVE
,bod.VendorProject as "Vendor/Project"
,bod.Product
,bod.VulnerabilityName
,bod.DateAddedToCatalog
,bod.ShortDescription
,bod.BODDueDate
,bod.exploitAvailable
,bod.FISMAseverity
,p.POAM_ID as "POA&M ID"
,vm.Total
,p.Overall_Status
FROM CORE.KEV_Catalog bod 
join (SELECT DATACENTER_ID,SYSTEM_ID,cve,count(1) as Total
    FROM CORE.VW_VULMASTER where IS_KEV = 1 and MitigationStatus <> 'fixed'
    group by DATACENTER_ID,SYSTEM_ID,cve) vm on vm.CVE = bod.cve
join CORE.VW_SYSTEMS dc on dc.SYSTEM_ID = vm.DATACENTER_ID
right outer join CORE.VW_SYSTEMS s on s.SYSTEM_ID = vm.SYSTEM_ID

left join (SELECT SYSTEM_ID, POAM_ID, Overall_Status,CVE
    FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0)) r
    JOIN CORE.VW_POAMHIST p on p.REPORT_ID = r.REPORT_ID
    WHERE p.CVE IS NOT NULL) p on p.SYSTEM_ID = vm.SYSTEM_ID and p.CVE = vm.CVE

order by dc.Acronym,s.Acronym,vm.CVE;