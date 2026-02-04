create or replace view VW_BOD_22_01(
	DATACENTER,
	CVE,
	VENDOR_PROJECT,
	PRODUCT,
	VULNERABILITYNAME,
	DATEADDEDTOCATALOG,
	SHORTDESCRIPTION,
	BODDUEDATE,
	TOTAL
) COMMENT='Return total assets affected by BOD or KEV for eatch datacent.'
 as
SELECT 
dc.Acronym as DataCenter
,vm.CVE
,bod.VendorProject as Vendor_Project
,bod.Product
,bod.VulnerabilityName
,bod.DateAddedToCatalog::date AS DateAddedToCatalog -- 270328 chg to date type
,bod.ShortDescription
,bod.BODDueDate::date as BODDueDate -- 270328 chg to date type
,count(1) Total
FROM CORE.VW_Assets a
join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = vm.DATACENTER_ID
JOIN CORE.KEV_CATALOG bod on bod.CVE = vm.cve
WHERE vm.MitigationStatus <> 'fixed' 
and bod.Is_Deleted = 0
group by dc.Acronym
,vm.CVE
,bod.VendorProject
,bod.Product
,bod.VulnerabilityName
,bod.DateAddedToCatalog::date -- 270328 chg to date type
,bod.ShortDescription
,bod.BODDueDate::date -- 270328 chg to date type
order by dc.Acronym
,vm.CVE
,bod.VendorProject 
,bod.Product
,bod.VulnerabilityName
,bod.DateAddedToCatalog::date -- 270328 chg to date type
,bod.ShortDescription
,bod.BODDueDate::date -- 270328 chg to date type;
;