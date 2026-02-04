create or replace view V_SYSTEMSUMMARY_MCRR_VULCOUNT(
	REPORTNAME,
	ACRONYM,
	VULNS_CNT,
	BUCKET,
	LESSTHAN25,
	LESSTHAN50,
	GREATERTHAN50,
	GREATERTHAN75,
	CRITICALGT15,
	HIGHGT30,
	MODERATEGT90,
	LOWGT365
) COMMENT='Vuln data details related to System information (Vuln Severity/Remediated Vulns/KEV''s / Buckets for Age etc)'
 as
  SELECT REPORTNAME
       ,ACRONYM
       ,vulns_cnt
       ,bucket
       ,LessThan25
        ,LessThan50
        ,GreaterThan50
        ,GreaterThan75
        ,CriticalGT15
        ,HighGT30
        ,ModerateGT90
        ,LowGT365
FROM   (SELECT reportname
            ,s.ACRONYM
            ,vuluniquecritical_gt15_lte60days
            ,vuluniquecritical_gt30_lte60days
            ,vuluniquecritical_gt60days
            ,vuluniquecritical_gte15days
            ,vuluniquehigh_gt30_lte60days
            ,vuluniquehigh_gt60days
            ,vulcritical_gt60days
            ,vulhigh_gt30_lte60days
            ,vulcritical_gt15_lte60days
			,vulhigh_gt60days
			,vuluniquemedium
			,vuluniquelow
			,vulmedium
			,vullow
            ,LessThan25
            ,LessThan50
            ,GreaterThan50
            ,GreaterThan75
            ,CriticalGT15
            ,HighGT30
            ,ModerateGT90
            ,LowGT365
        FROM CORE.VW_SYSTEMSUMMARY ss
		join CORE.VW_SYSTEMS s on ss.system_id = s.system_id
        --CR #577
        left join (select system_id, sum(Q1)+ sum(Q2) + sum(Q3) as LessThan25,sum(Q4) as LessThan50, sum(Q5) as GreaterThan50, sum(Q6) as GreaterThan75 from (SELECT system_id, 
       "'NULL'" AS Q1,
      "'<=0%'" AS Q2,
       "'> 0% and <= 25%'" AS Q3, 
       "'> 25% and <= 50%'" AS Q4, 
       "'> 50% and <= 75%'" AS Q5,
       "'> 75% and <= 100%'" AS Q6
  FROM RPT.VW_ASSETDETAIL_ROLLING60DAYS
    PIVOT(count(CVE) FOR EPSS_FILTER IN (
      'NULL',
      '<=0%',
      '> 0% and <= 25%', 
      '> 25% and <= 50%', 
      '> 50% and <= 75%', 
      '> 75% and <= 100%')
    ) where lower(MitigationStatus) in ('open', 'reopened'))group by system_id)vulcur on ss.system_id = vulcur.system_id  
       left join (select system_id, sum(Q1) CriticalGT15,sum(Q2) as HighGT30, sum(Q3) as ModerateGT90, sum(Q4) as LowGT365 from 
           (SELECT system_id, 
       "'OVERDUE CRITICAL'" AS Q1,
       "'OVERDUE HIGH'" AS Q2,
       "'OVERDUE MODERATE'" AS Q3, 
       "'OVERDUE LOW'" AS Q4
  FROM RPT.VW_ASSETDETAIL_ROLLING60DAYS 
    PIVOT(count(CVE) FOR OVERDUE_FILTER IN (
      'OVERDUE CRITICAL',
      'OVERDUE HIGH',
      'OVERDUE MODERATE', 
      'OVERDUE LOW')
    )where lower(MitigationStatus) in ('open', 'reopened'))group by system_id)vulDays on ss.system_id = vulDays.system_id    
        
		 LEFT JOIN (
  select * from rpt.CRR_COMPONENT_PARAMS
) reportName ON (s.ACRONYM = reportName.Systems) AND (component_acronym = reportName.Component) AND (group_acronym = reportName.Groups)
        WHERE  report_id = (SELECT max(REPORT_ID) FROM core.report_ids where is_endofmonth = 1))data
       UNPIVOT(vulns_cnt
              FOR bucket IN ( vuluniquecritical_gt15_lte60days
            ,vuluniquecritical_gt30_lte60days
            ,vuluniquecritical_gt60days
            ,vuluniquecritical_gte15days
            ,vuluniquehigh_gt30_lte60days
            ,vuluniquehigh_gt60days
            ,vulcritical_gt60days
            ,vulhigh_gt30_lte60days
            ,vulcritical_gt15_lte60days
			,vulhigh_gt60days
			,vuluniquemedium
			,vuluniquelow
			,vulmedium
			,vullow ) ) AS mrks;