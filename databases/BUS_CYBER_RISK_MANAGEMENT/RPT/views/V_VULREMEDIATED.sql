create or replace view V_VULREMEDIATED(
	DATACENTERACRONYM,
	SYSTEMACRONYM,
	REMEDIATEDCURMONTH,
	REMEDIATEDPRIORMONTH
) COMMENT='Returns remediated CVE count for current and previous month'
 as
WITH
dateFilters as (select cast(cast(MONTH(CURRENT_TIMESTAMP) as varchar) || '/01/' || cast(year(CURRENT_TIMESTAMP) as varchar) as date) as startOfcurMonth
,cast(cast(MONTH(DATEADD(M,-1,CURRENT_TIMESTAMP)) as varchar) || '/01/' || cast(year(DATEADD(M,-1,CURRENT_TIMESTAMP)) as varchar) as date) as startOfprevMonth
),
prevMonth as (select a.DATACENTER_ID,count(1) remediatedPriorMonth
	from CORE.VW_VulMaster vm
	JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID
	where vm.datemitigated >= (select startOfprevMonth from dateFilters)
	and vm.datemitigated < (select startOfcurMonth from dateFilters)
	GROUP BY a.DATACENTER_ID
),
curMonth as (select a.DATACENTER_ID,count(1) remediatedCurMonth
	from CORE.VW_VulMaster vm
	JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID
	where vm.datemitigated >= (select startOfcurMonth from dateFilters)
	and vm.datemitigated < CURRENT_TIMESTAMP
	GROUP BY a.DATACENTER_ID
)
select 
s.PRIMARY_OPERATING_LOCATION_ACRONYM DataCenterAcronym
,s.Acronym as SystemAcronym
,coalesce(cm.remediatedCurMonth,0) as remediatedCurMonth
,coalesce(pm.remediatedPriorMonth,0) as remediatedPriorMonth
FROM CORE.VW_SYSTEMS s
left outer join prevMonth pm on pm.DATACENTER_ID = s.SYSTEM_ID
left outer join curMonth cm on cm.DATACENTER_ID = s.SYSTEM_ID
where pm.DATACENTER_ID is not null OR cm.DATACENTER_ID IS NOT NULL
;