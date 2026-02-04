create or replace view VW_BOD_22_01_SYSTEMBREAKDOWN(
	DATACENTER,
	SYSTEM,
	CVE,
	VENDOR_PROJECT,
	PRODUCT,
	VULNERABILITYNAME,
	DATEADDEDTOCATALOG,
	SHORTDESCRIPTION,
	BODDUEDATE,
	TOTAL
) COMMENT='Return total assets affected by BOD or KEV for each system.'
 as
SELECT 
dc.Acronym as DataCenter
,s.Acronym as System
,vm.CVE
,bod.VendorProject as Vendor_Project
,bod.Product
,bod.VulnerabilityName
,bod.DateAddedToCatalog::date as DateAddedToCatalog -- 270328 chg to date type
,bod.ShortDescription
,bod.BODDueDate::date as BODDueDate -- 270328 chg to date type
,count(1) Total
FROM CORE.VW_Assets a
JOIN CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
JOIN CORE.TEMP_BOD tb on tb.CVE = vm.CVE -- 240319 CR855
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = vm.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
JOIN CORE.KEV_CATALOG bod on bod.CVE = vm.cve
WHERE vm.MitigationStatus <> 'fixed' 
and bod.Is_Deleted = 0
group by dc.Acronym
,s.Acronym
,vm.CVE
,bod.VendorProject
,bod.Product
,bod.VulnerabilityName
,bod.DateAddedToCatalog::date -- 270328 chg to date type
,bod.ShortDescription
,bod.BODDueDate::date -- 270328 chg to date type
order by dc.Acronym
,s.Acronym
,vm.CVE
,bod.VendorProject 
,bod.Product
,bod.VulnerabilityName
,bod.DateAddedToCatalog::date -- 270328 chg to date type
,bod.ShortDescription
,bod.BODDueDate::date -- 270328 chg to date type;
;