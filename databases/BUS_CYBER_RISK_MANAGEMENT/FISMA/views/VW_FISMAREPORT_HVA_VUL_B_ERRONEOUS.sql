create or replace view VW_FISMAREPORT_HVA_VUL_B_ERRONEOUS(
	"FIPS 199 Category",
	"1.1.5. Total # of HVA Systems",
	"2.16. Total unique Critical CVE > 30 days",
	"2.16.1. Total unique High CVE > 60 days"
) COMMENT='Shows total HVA systems, unique total critical and high vuln for each FIPS 199 Category with EDC4 excluded. '
 as
SELECT 
fips.FIPS_199_Category as "FIPS 199 Category",coalesce(totsys.TotalHVASystems,0) as "1.1.5. Total # of HVA Systems"
,coalesce("FISMA_2.16".TotalUnqiueCVEs,0) as "2.16. Total unique Critical CVE > 30 days"
,coalesce("FISMA_2.16.1".TotalUnqiueCVEs,0) as "2.16.1. Total unique High CVE > 60 days"
FROM (
select 'High' as FIPS_199_Category, 1 as "Order"
UNION ALL
select 'Moderate' as FIPS_199_Category, 2 as "Order"
UNION ALL
select 'Low' as FIPS_199_Category, 3 as "Order"
) fips
LEFT OUTER JOIN (SELECT sh.FIPS_199_Overall_Impact_Rating,count(1) as TotalHVASystems
	FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) csnap
	JOIN CORE.VW_SystemsHist sh on sh.REPORT_ID = csnap.REPORT_ID 
	JOIN CORE.VW_Systems s on s.System_ID = sh.System_ID
	where coalesce(sh.HVAStatus,'Fake') = 'Yes' 
	and s.Acronym <> 'EDC4' 
	GROUP BY sh.FIPS_199_Overall_Impact_Rating) totsys on totsys.FIPS_199_Overall_Impact_Rating = fips.FIPS_199_Category

LEFT OUTER JOIN (select uniqueSysCriticalCVE.FIPS_199_Overall_Impact_Rating,SUM(uniqueSysCriticalCVE.TotalUnqiueCVEs) as TotalUnqiueCVEs
	FROM (SELECT FIPS_199_Overall_Impact_Rating
		  ,count(1) TotalUnqiueCVEs
		FROM (SELECT uniqueSysCriticalCVE.FIPS_199_Overall_Impact_Rating,uniqueSysCriticalCVE.cve
			FROM (SELECT distinct sh.FIPS_199_Overall_Impact_Rating
			,v.cve
			FROM CORE.VW_VulHist v
			join TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) vsnap on vsnap.REPORT_ID = v.REPORT_ID
			join TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) csnap on csnap.REPORT_ID = vsnap.REPORT_ID
			JOIN CORE.VW_SystemsHist sh on sh.REPORT_ID = csnap.REPORT_ID and sh.System_ID = v.System_ID
			JOIN CORE.VW_Systems s on s.System_ID = v.System_ID
	--		where v.RowDisposition = 'C'
			where v.MitigationStatus IN ('open','reopened')
			and cast(v.CVSSV2BASESCORE as real) >= 9.0 and cast(v.CVSSV2BASESCORE as real) <= 10.0
			and coalesce(sh.HVAStatus,'Fake') = 'Yes'
			and s.Acronym <> 'EDC4'  
			and v.DaysSinceDiscovery > 30) uniqueSysCriticalCVE 
			) criticalCVEs
			group by criticalCVEs.FIPS_199_Overall_Impact_Rating) uniqueSysCriticalCVE
	GROUP BY uniqueSysCriticalCVE.FIPS_199_Overall_Impact_Rating) "FISMA_2.16" on "FISMA_2.16".FIPS_199_Overall_Impact_Rating = fips.FIPS_199_Category

LEFT OUTER JOIN (select uniqueSysHighCVE.FIPS_199_Overall_Impact_Rating,SUM(uniqueSysHighCVE.TotalUnqiueCVEs) as TotalUnqiueCVEs
	FROM (SELECT FIPS_199_Overall_Impact_Rating
		  ,count(1) TotalUnqiueCVEs
		FROM (SELECT uniqueSysHighCVE.FIPS_199_Overall_Impact_Rating,uniqueSysHighCVE.cve
			FROM (SELECT distinct sh.FIPS_199_Overall_Impact_Rating
			,v.cve
			FROM CORE.VW_VulHist v
			join TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) vsnap on vsnap.REPORT_ID = v.REPORT_ID
			join TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) csnap on csnap.REPORT_ID = vsnap.REPORT_ID
			JOIN CORE.VW_SystemsHist sh on sh.REPORT_ID = csnap.REPORT_ID and sh.System_ID = v.System_ID
			JOIN CORE.VW_Systems s on s.System_ID = v.System_ID
	--		where v.RowDisposition = 'C'
			where v.MitigationStatus IN ('open','reopened')
			and cast(v.CVSSV2BASESCORE as real) >= 7.0 and cast(v.CVSSV2BASESCORE as real) <= 8.9
			and coalesce(sh.HVAStatus,'Fake') = 'Yes'
			and s.Acronym <> 'EDC4'  
			and v.DaysSinceDiscovery > 60) uniqueSysHighCVE 
			) HighCVEs
			group by HighCVEs.FIPS_199_Overall_Impact_Rating) uniqueSysHighCVE
	GROUP BY uniqueSysHighCVE.FIPS_199_Overall_Impact_Rating) "FISMA_2.16.1" on "FISMA_2.16.1".FIPS_199_Overall_Impact_Rating = fips.FIPS_199_Category
ORDER BY fips."Order";