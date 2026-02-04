create or replace view VW_BOD_22_01_TEMPLATE_WORKSHEET_V2(
	CVE,
	"Date Added",
	"Vulnerability Name",
	"Total Findings",
	"Challenges and Constraints",
	"Finding Justification",
	"Estimated Completion Date",
	DELETECOLUMNS,
	COUNT_OF_OPEN_POAMS,
	CURRENT_DATE_PLUS_30,
	PREV_POAM_ACTUAL_COMPLETION_DATE
) COMMENT='Return results needed for BOD Template Worksheet.'
 as
--
-- 240731 CR918 - New version
--
-- OVERALL_STATUS values found in CFACTS POAMS data:
-- Closed for System Retired
-- Completed
-- Delayed
-- Draft
-- Ongoing
-- Pending Verification
-- Risk Accepted
-- 
select
sbod.CVE as "CVE"
,sbod.DATEADDED as "Date Added"
,sbod.VULNERABILITYNAME as "Vulnerability Name"
,coalesce(v.Total,0) as "Total Findings"
,'' as "Challenges and Constraints"
,'' as "Finding Justification"
,case coalesce(v.Total,0) 
    when 0 then ''
    Else 
        case coalesce(est.COUNT_OF_OPEN_POAMS,0)
            when 0 THEN TO_CHAR(dateadd(d,30,current_date()),'MM/DD/YYYY')
            Else TO_CHAR(est.MAX_ESTIMATED_COMPLETION_DATE,'MM/DD/YYYY')
        End
End as "Estimated Completion Date"
,'DELETE THIS COLUMN AND EVERY COLUMN TO THE RIGHT' as DELETECOLUMNS
,coalesce(est.COUNT_OF_OPEN_POAMS,0) as COUNT_OF_OPEN_POAMS
,TO_CHAR(dateadd(d,30,current_date()),'MM/DD/YYYY') as CURRENT_DATE_PLUS_30
,TO_CHAR(completedPoam.MAX_ACTUAL_COMPLETION_DATE,'MM/DD/YYYY') as PREV_POAM_ACTUAL_COMPLETION_DATE
FROM CORE.TEMP_BOD sbod
LEFT OUTER JOIN CORE.KEV_CATALOG kev on kev.cve = sbod.cve
LEFT OUTER JOIN (select CVE,SUM(Total) as Total
    FROM CORE.VW_BOD_22_01_SYSTEMBREAKDOWN
    GROUP BY CVE) v on v.CVE = sbod.CVE
LEFT OUTER JOIN (select CVE,count(1) COUNT_OF_OPEN_POAMS,MAX(ESTIMATED_COMPLETION_DATE) as MAX_ESTIMATED_COMPLETION_DATE
    FROM CORE.VW_POAMS
    WHERE CVE IS NOT NULL and OVERALL_STATUS NOT IN ('Completed','Closed for System Retired')
    GROUP BY CVE) est on est.CVE = sbod.CVE

LEFT OUTER JOIN (select CVE,MAX(ACTUAL_COMPLETION_DATE) as MAX_ACTUAL_COMPLETION_DATE
    FROM CORE.VW_POAMS
    WHERE CVE IS NOT NULL and OVERALL_STATUS IN ('Completed','Closed for System Retired','Risk Accepted')
    GROUP BY CVE) completedPoam on completedPoam.CVE = sbod.CVE

ORDER BY sbod.DATEADDED::date desc, sbod.CVE
;