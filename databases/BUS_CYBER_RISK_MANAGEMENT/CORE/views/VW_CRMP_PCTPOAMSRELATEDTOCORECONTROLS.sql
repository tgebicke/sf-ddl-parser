create or replace view VW_CRMP_PCTPOAMSRELATEDTOCORECONTROLS(
	ACRONYM,
	TOTALPOAM,
	COREPOAM,
	PARCENTAGECORE
) COMMENT='Shows percentage of POAM for core controls for every system, used for CRMP.'
 as
With CorePoam AS (
SELECT 
s.Acronym
,count(1) CorePoam
FROM table(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.VW_POAMHist p on p.REPORT_ID = r.REPORT_ID
INNER JOIN CORE.VW_Systems s ON s.SYSTEM_ID=p.SYSTEM_ID
WHERE p.Overall_Status in ('Delayed', 'Ongoing', 'Draft')
and REPLACE(p.Target,'Allocated_Control: ','') in  
('AC-1','AC-2','AC-3','AC-5','AC-6','AC-17','CA-3','CM-2','CM-3','CM-6','CM-7','CP-2','CP-3','CP-4','CP-4(1)','IA-2','IA-5','IR-5','IR-6','IR-6(1)','PL-2','SC-7','SC-8','SC-13','SI-2','HVA Additional Controls','AU-6','CA-5','IA-5(1)')
group by s.Acronym
),
TotalPoam AS(
SELECT 
s.Acronym
,count(1) TotalPoam
FROM table(CORE.FN_CRM_GET_REPORT_ID(0)) r
JOIN CORE.VW_POAMHist p on p.REPORT_ID = r.REPORT_ID
INNER JOIN CORE.VW_Systems s ON s.SYSTEM_ID=p.SYSTEM_ID
WHERE p.Overall_Status in ('Delayed', 'Ongoing', 'Draft')
group by s.Acronym
)
Select tp.Acronym, tp.TotalPoam,coalesce(cp.CorePoam,0) as CorePoam,cast (coalesce(cp.CorePoam,0)*100.00/tp.TotalPoam as decimal(6,2)) as ParcentageCore From TotalPoam tp left join CorePoam cp ON tp.Acronym=cp.Acronym
;