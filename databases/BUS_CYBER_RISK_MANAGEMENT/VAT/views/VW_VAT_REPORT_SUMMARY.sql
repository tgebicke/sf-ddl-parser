create or replace view VW_VAT_REPORT_SUMMARY(
	SNAPSHOT_DATE,
	DATACENTERACRONYM,
	COMMONNAME,
	ASSETS,
	CRITICALFIXEDINLAST15DAYS,
	CRITICALOPEN,
	CRITICALREOPENED,
	HIGHFIXEDINLAST15DAYS,
	HIGHOPEN,
	HIGHREOPENED,
	RECENTOPENORREOPENCRITCAL,
	RECENTOPENORREOPENHIGH,
	RECENTRAWANYVUL,
	RECENTRAWCRITICAL,
	RECENTRAWHIGH,
	RECENTRAWMEDIUM,
	RECENTRAWLOW
) as
with
q_Datacenters as (select DISTINCT DATACENTER_ID
	FROM CORE.VW_Assets a
),
q_Assets as (select qdc.DATACENTER_ID,count(1) as Total
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
--	where a.Is_Applicable = 1
	group by qdc.DATACENTER_ID
),
q_CriticalFixedInLast15days as (select qdc.DATACENTER_ID,count(1) as Total 
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where vm.FISMAseverity = 'Critical' and vm.MitigationStatus = 'fixed'-- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and 
	and datediff(d,vm.datemitigated,CURRENT_TIMESTAMP) <= 15
	group by qdc.DATACENTER_ID
),
q_HighFixedInLast15days as (select qdc.DATACENTER_ID,count(1) as Total 
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where  vm.FISMAseverity = 'High' and vm.MitigationStatus = 'fixed' -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and
	and datediff(d,vm.datemitigated,CURRENT_TIMESTAMP) <= 15
	group by qdc.DATACENTER_ID
),
q_CriticalOpen as (select qdc.DATACENTER_ID,count(1) as Total
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where vm.FISMAseverity = 'Critical' and vm.MitigationStatus = 'Open' -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and 
	group by qdc.DATACENTER_ID
),
q_RecentCriticalOpenOrRepopen as (select qdc.DATACENTER_ID,max(vm.lastfound)::VARCHAR as lastFound -- 220810 1419
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where vm.FISMAseverity = 'Critical' and vm.MitigationStatus <> 'fixed' -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and
	group by qdc.DATACENTER_ID
),
q_RecentHighOpenOrRepopen as (select qdc.DATACENTER_ID,max(vm.lastfound)::VARCHAR as lastFound -- 220810 1419
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where vm.FISMAseverity = 'High' and vm.MitigationStatus <> 'fixed' -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and
	group by qdc.DATACENTER_ID
),
q_CriticalReOpened as (select qdc.DATACENTER_ID,count(1) as Total
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where vm.FISMAseverity = 'Critical' and vm.MitigationStatus = 'Reopened' -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and 
	group by qdc.DATACENTER_ID
),
q_HighOpen as (select qdc.DATACENTER_ID,count(1) as Total
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where  vm.FISMAseverity = 'High' and vm.MitigationStatus = 'Open' -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and
	group by qdc.DATACENTER_ID
),
q_HighReOpened as (select qdc.DATACENTER_ID,count(1) as Total
	FROM q_Datacenters qdc
	JOIN CORE.VW_Assets a on a.DATACENTER_ID = qdc.DATACENTER_ID
	join CORE.VW_VulMaster vm on vm.DW_ASSET_ID = a.DW_ASSET_ID
	where vm.FISMAseverity = 'High' and vm.MitigationStatus = 'Reopened' -- a.Is_Applicable = 1 and vm.DeletionReason IS NULL and 
	group by qdc.DATACENTER_ID
),
q_RecentRawVul as (select dc.SYSTEM_ID as DATACENTER_ID, v.INSERT_DATE::VARCHAR as INSERT_DATE
	FROM CORE.VW_Systems  dc
	JOIN (select datacenter_id,max(INSERT_DATE) as INSERT_DATE
	FROM CORE.RAW_TENABLE_VUL 
	group by datacenter_id) v on v.datacenter_id = dc.SYSTEM_ID
),
q_RecentRawCritical as (select dc.SYSTEM_ID as DATACENTER_ID, v.INSERT_DATE::VARCHAR as INSERT_DATE
	FROM CORE.VW_Systems  dc
	JOIN (select datacenter_id,max(INSERT_DATE) as INSERT_DATE
	FROM CORE.RAW_TENABLE_VUL 
	where FISMAseverity = 'Critical'
	group by datacenter_id) v on v.datacenter_id = dc.SYSTEM_ID
),
q_RecentRawHigh as (select dc.SYSTEM_ID as DATACENTER_ID, v.INSERT_DATE::VARCHAR as INSERT_DATE
	FROM CORE.VW_Systems  dc
	JOIN (select datacenter_id,max(INSERT_DATE) as INSERT_DATE
	FROM CORE.RAW_TENABLE_VUL 
	where FISMAseverity = 'High'
	group by datacenter_id) v on v.datacenter_id = dc.SYSTEM_ID
),
q_RecentRawMedium as (select dc.SYSTEM_ID as DATACENTER_ID, v.INSERT_DATE::VARCHAR as INSERT_DATE 
	FROM CORE.VW_Systems  dc
	JOIN (select datacenter_id,max(INSERT_DATE) as INSERT_DATE
	FROM CORE.RAW_TENABLE_VUL 
	where FISMAseverity = 'Medium'
	group by datacenter_id) v on v.datacenter_id = dc.SYSTEM_ID
),
q_RecentRawLow as (select dc.SYSTEM_ID as DATACENTER_ID, v.INSERT_DATE::VARCHAR as INSERT_DATE 
	FROM CORE.VW_Systems  dc
	JOIN (select datacenter_id,max(INSERT_DATE) as INSERT_DATE
	FROM CORE.RAW_TENABLE_VUL 
	where FISMAseverity = 'Low'
	group by datacenter_id) v on v.datacenter_id = dc.SYSTEM_ID
)
SELECT 
(select DISTINCT substring(SNAPSHOT_DATE::VARCHAR,1,16)
	from CORE.VW_REPORTSNAPSHOTS WHERE REPORT_DATE = (SELECT max(vh.REPORT_DATE) from CORE.VW_VULHIST vh)) AS SNAPSHOT_DATE
,dc.Acronym as DatacenterAcronym
,dc.CommonName as CommonName
,qa.Total as Assets
,coalesce(qcf15.Total,0) as CriticalFixedInLast15days 
,coalesce(qco.Total,0) as CriticalOpen
,coalesce(qcr.Total,0) as CriticalReopened
,coalesce(qhf15.Total,0) as HighFixedInLast15days 
,coalesce(qho.Total,0) as HighOpen
,coalesce(qhr.Total,0) as HighReopened
,qrcOpen.lastFound as RecentOpenOrReopenCritcal 
,qrhOpen.lastFound as RecentOpenOrReopenHigh 
,qrv.INSERT_DATE as RecentRawAnyVul
,qrc.INSERT_DATE as RecentRawCritical
,qrh.INSERT_DATE as RecentRawHigh
,qrm.INSERT_DATE as RecentRawMedium
,qrl.INSERT_DATE as RecentRawLow
from q_Datacenters qdc
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = qdc.DATACENTER_ID
join q_Assets qa on qa.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_CriticalFixedInLast15days qcf15 on qcf15.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_CriticalOpen qco on qco.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_CriticalReOpened qcr on qcr.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_HighFixedInLast15days qhf15 on qhf15.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_HighOpen qho on qho.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_HighReOpened qhr on qhr.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_RecentCriticalOpenOrRepopen qrcOpen on qrcOpen.DATACENTER_ID = qdc.DATACENTER_ID 
left outer join q_RecentHighOpenOrRepopen qrhOpen on qrhOpen.DATACENTER_ID = qdc.DATACENTER_ID 
left outer join q_RecentRawVul qrv on qrv.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_RecentRawCritical qrc on qrc.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_RecentRawHigh qrh on qrh.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_RecentRawMedium qrm on qrm.DATACENTER_ID = qdc.DATACENTER_ID
left outer join q_RecentRawLow qrl on qrl.DATACENTER_ID = qdc.DATACENTER_ID
order by dc.Acronym
;