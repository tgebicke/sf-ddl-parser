create or replace view VW_BOD_ED_22_02_CVEUNREMEDIATED_REPORTING_TEMPLATE_221012_1224(
	CVE_ID,
	VENDOR_PROJECT,
	PRODUCT,
	VULNERABILITY_NAME,
	DATE_ADDED,
	SHORT_DESCRIPTION,
	REQUIRED_ACTION,
	DUE_DATE,
	TOTAL_FINDINGS_UNREMEDIATED_ASSETS,
	CHALLENGES_CONSTRAINTS_FINDING_JUSTIFICATION,
	ESTIMATED_REMEDIATION_DATE
) COMMENT='Old version of \"VW_BOD_ED_22_02_CVEUNREMEDIATED_REPORTING_TEMPLATE\"'
 as
SELECT  bod.CVE as CVE_ID
,bod.VendorProject as Vendor_Project
,bod.Product
,bod.VulnerabilityName as Vulnerability_Name
,bod.DateAddedToCatalog as Date_Added
,bod.ShortDescription as Short_Description
,bod.RequiredAction as Required_Action
,bod.BODDueDate as Due_Date
,coalesce(vm.TotalUnremediatedAssets,0) as Total_Findings_Unremediated_Assets
,'' as Challenges_Constraints_Finding_Justification
,'' as Estimated_Remediation_Date
FROM CORE.KEV_CATALOG bod
LEFT OUTER JOIN (select vm.cve, count(1) TotalUnremediatedAssets
	FROM CORE.VW_Assets a
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	WHERE vm.MitigationStatus <> 'fixed' 
	-- and a.Is_Applicable = 1
	-- and vm.DeletionReason IS NULL
	group by vm.cve) vm on vm.cve = bod.CVE
where bod.Is_Deleted = 0
order by bod.CVE
,bod.VulnerabilityName
;