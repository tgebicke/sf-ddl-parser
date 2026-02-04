create or replace view VW_BOD_ED_22_02_CVEUNREMEDIATED_REPORTING_TEMPLATE(
	CVE,
	"Date Added",
	"Vulnerability Name",
	"Total Findings",
	"Challenges and Constraints",
	"Finding Justification",
	"Estimated Completion Date"
) COMMENT='Used for CMS IMT biweekly BOD report showing total finding for eatch BOD CVE.'
 as
SELECT bod.CVE as "CVE"
,bod.DateAddedToCatalog as "Date Added"
,bod.VulnerabilityName as "Vulnerability Name"
,coalesce(vm.TotalUnremediatedAssets,0) as "Total Findings"
,'' as "Challenges and Constraints"
,'' as "Finding Justification"
,'' as "Estimated Completion Date"
FROM CORE.KEV_Catalog bod
LEFT OUTER JOIN (select vm.cve, count(1) TotalUnremediatedAssets
	FROM CORE.VW_ASSETS a
	JOIN CORE.VW_VulMaster vm on vm.DW_Asset_ID = a.DW_Asset_ID
	WHERE vm.MitigationStatus <> 'fixed' 
	group by vm.cve) vm on vm.cve = bod.CVE
where bod.Is_Deleted = 0
order by bod.CVE
,bod.VulnerabilityName;