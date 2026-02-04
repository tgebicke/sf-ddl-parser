create or replace view VW_BOD_ED_22_02_CVEUNREMEDIATED_REPORTING_TEMPLATE_220812_1300(
	CVE,
	DATE_ADDED,
	VULNERABILITY_NAME,
	TOTAL_FINDINGS_UNREMEDIATED_ASSETS,
	CHALLENGES_CONSTRAINTS,
	FINDING_JUSTIFICATION,
	ESTIMATED_REMEDIATION_DATE
) COMMENT='Old version of \"VW_BOD_ED_22_02_CVEUNREMEDIATED_REPORTING_TEMPLATE\"'
 as
SELECT  bod.CVE
,bod.DateAddedToCatalog as Date_Added
,bod.VulnerabilityName as Vulnerability_Name
,coalesce(vm.TotalUnremediatedAssets,0) as Total_Findings_Unremediated_Assets
,'' as Challenges_Constraints
,'' as Finding_Justification
,'' as Estimated_Remediation_Date
FROM CORE.KEV_CATALOG bod
LEFT OUTER JOIN (select vm.cve, count(1) as TotalUnremediatedAssets
	FROM CORE.VW_Assets a
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	WHERE vm.MitigationStatus <> 'fixed' 
    -- and a.Is_Applicable = 1
    -- and vm.DeletionReason IS NULL
	group by vm.cve) vm on vm.cve = bod.CVE
where bod.Is_Deleted = 0
order by bod.CVE
,bod.VulnerabilityName;