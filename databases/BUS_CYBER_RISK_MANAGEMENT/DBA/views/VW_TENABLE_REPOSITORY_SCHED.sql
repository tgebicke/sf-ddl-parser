create or replace view VW_TENABLE_REPOSITORY_SCHED(
	DATECOLUMNNAME,
	ACRONYM,
	RAW_TENABLE_VUL_COUNT,
	REPOSITORY_ID,
	REPOSITORY_NAME
) COMMENT='UNDER DEVELOPMENT; View to list all Tenable Repositories and the dates see in pivot table format\t'
 as
SELECT 
--substring(rh.INSERT_DATE::varchar,1,16) as INSERT_DATE
--rh.INSERT_DATE::date || ' ' || upper(dayname(rh.INSERT_DATE::date)) as DATECOLUMNNAME
rh.LAST_SEEN::date || ' ' || upper(dayname(rh.LAST_SEEN::date)) as DATECOLUMNNAME
,dc.ACRONYM
--,rh.INSERT_DATE::date as INSERT_DATE
,rh.RAW_TENABLE_VUL_COUNT
,rh.REPOSITORY_ID
,rh.REPOSITORY_NAME
FROM CORE.TENABLE_REPOSITORYHIST rh
left outer join CORE.SYSTEMS dc on dc.SYSTEM_ID = rh.DATACENTER_ID

where rh.REPOSITORY_ID IS NOT NULL and DATEDIFF(day,rh.insert_date,current_date()) <= 90
--ORDER BY rh.TENABLE_REPOSITORYHIST_ID DESC
;