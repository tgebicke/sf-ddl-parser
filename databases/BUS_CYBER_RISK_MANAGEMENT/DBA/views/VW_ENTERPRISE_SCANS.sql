create or replace view VW_ENTERPRISE_SCANS(
	REPORT_ID,
	REPORT_DATE,
	YYMM,
	TOTAL_ASSETS,
	SCANABLE_ASSETS,
	ASSETS_SCANNED_TODAY,
	ASSETS_SCANNED_WITNIN_3_DAYS,
	ASSETS_SCANNED
) COMMENT='Reports enterprise scans totals\t'
 as
select t.REPORT_ID,t.REPORT_DATE,t.YYMM
    ,coalesce(a.TOTAL_ASSETS,0) as TOTAL_ASSETS
    ,coalesce(scanable.SCANABLE_ASSETS,0) as SCANABLE_ASSETS
    ,coalesce(scantoday.ASSETS_SCANNED_TODAY,0) as ASSETS_SCANNED_TODAY
    ,coalesce(scanwithin3.ASSETS_SCANNED_WITNIN_3_DAYS,0) as ASSETS_SCANNED_WITNIN_3_DAYS
    ,coalesce(scan.ASSETS_SCANNED,0) as ASSETS_SCANNED
FROM (SELECT r1.REPORT_ID,r1.REPORT_DATE,to_char(r1.REPORT_DATE,'YYMM') as YYMM
        FROM (select rank()over(partition by REPORT_ID order by REPORT_DATE::date) TheRank,REPORT_ID,REPORT_DATE::date as REPORT_DATE
            FROM CORE.REPORT_IDS where is_viable = 1 and REPORT_DATE::date >= '2024-02-01'::date) r1 where r1.TheRank = 1) t

left outer join (select  r.REPORT_ID,count(1) as TOTAL_ASSETS
    FROM CORE.REPORT_IDS r
    JOIN CORE.ASSETHIST ah on ah.REPORT_ID = r.REPORT_ID
    GROUP BY r.REPORT_ID,r.REPORT_DATE::date) a on a.REPORT_ID = t.REPORT_ID

left outer join (select  r.REPORT_ID,count(1) as SCANABLE_ASSETS
    FROM CORE.REPORT_IDS r
    JOIN CORE.ASSETHIST ah on ah.REPORT_ID = r.REPORT_ID
    WHERE ah.is_scannable = 1
    GROUP BY r.REPORT_ID,r.REPORT_DATE::date) scanable on scanable.REPORT_ID = t.REPORT_ID
    
left outer join (select r.REPORT_ID,count(1) as ASSETS_SCANNED_TODAY
    FROM CORE.REPORT_IDS r
    JOIN CORE.ASSETHIST ah on ah.REPORT_ID = r.REPORT_ID
    WHERE ah.is_scannable = 1 and ah.LASTSEEN_VUL IS NOT NULL and ah.LASTSEEN_VUL::date = r.REPORT_DATE::date
    GROUP BY r.REPORT_ID,r.REPORT_DATE::date) scantoday on scantoday.REPORT_ID = a.REPORT_ID

left outer join (select r.REPORT_ID,count(1) as ASSETS_SCANNED
    FROM CORE.REPORT_IDS r
    JOIN CORE.ASSETHIST ah on ah.REPORT_ID = r.REPORT_ID
    WHERE ah.is_scannable = 1 and ah.LASTSEEN_VUL IS NOT NULL
    GROUP BY r.REPORT_ID,r.REPORT_DATE::date) scan on scan.REPORT_ID = a.REPORT_ID

left outer join (select r.REPORT_ID,count(1) as ASSETS_SCANNED_WITNIN_3_DAYS
    FROM CORE.REPORT_IDS r
    JOIN CORE.ASSETHIST ah on ah.REPORT_ID = r.REPORT_ID
    WHERE ah.is_scannable = 1 and ah.LASTSEEN_VUL IS NOT NULL and DATEDIFF(day, ah.LASTSEEN_VUL, r.REPORT_DATE) <= 3
    GROUP BY r.REPORT_ID,r.REPORT_DATE::date) scanwithin3 on scanwithin3.REPORT_ID = a.REPORT_ID
    
;