create or replace view VW_VULN_DASHBOARD_TRENDING(
	ACRONYM,
	COMPONENT_ACRONYM,
	"CVE Count",
	"Unique CVE Count",
	CURRENTMTDSTART,
	DATA_CENTER_NAME,
	DATECREATED,
	DATEMITIGATED,
	DAYSSINCEDISCOVERY,
	EXPLOITAVAILABLE,
	FISMASEVERITY,
	HVASTATUS,
	IS_BOD,
	IS_MARKETPLACE,
	MEFSTATUS,
	MITIGATIONSTATUS,
	MTDVSEOM,
	PREVEOMSTART,
	RANKK,
	REFRESH_DATE,
	REPORT_DATE,
	REPORT_ID,
	TLC_PHASE,
	VULNRISKTOLERANCE
) COMMENT='Used to populate RPT.Temp_Vuln_Trending from within CORE.SP_CRM_WRITE_REPORTINGTABLES'
 as
with ReportIDs as(
(SELECT TOP 1 1 as RANKK, REPORT_ID, REPORT_DATE::DATE as REPORT_DATE, IS_ENDOFMONTH FROM CORE.REPORT_IDS ORDER BY REPORT_ID DESC) 
UNION ALL
(SELECT TOP 12 dense_rank()over(order by REPORT_ID desc) + 1 as RANNK, REPORT_ID, REPORT_DATE::DATE as REPORT_DATE,  IS_ENDOFMONTH FROM CORE.REPORT_IDS WHERE IS_ENDOFMONTH = 1 ORDER BY REPORT_ID DESC)
),
snap as (
select a.RANKK,a.REPORT_ID,a.REPORT_DATE,a.IS_ENDOFMONTH
,IFF(a.RANKK=1,'MTD',IFF(a.RANKK=2,'EOM','EOM-' || (a.RANKK-2)::VARCHAR )) as MTDVSEOM 
,IFF(a.RANKK=1,b.REPORT_DATE,a.REPORT_DATE) as CurrentMTDStart 
,IFF(a.RANKK in (1,2),(Select REPORT_DATE from ReportIDs  where RANKK=3 ),IFNULL(b.REPORT_DATE,a.REPORT_DATE))  as PrevEOMStart
from ReportIDs a left join ReportIDs b on a.RANKK=b.RANKK-1 
),
vulh as (
select  
s.SYSTEM_ID -- 241107 CR1026 was using upper function
,s.Component_Acronym
,count(vh.cve) as cvecount
,count(Distinct vh.cve) as UniqueCVECount
,ah.DATACENTER_ID
,vh.VUL_DATECREATED as datecreated
,vh.DATEMITIGATED
,sum(datediff(day,vh.FIRSTSEEN,vh.LASTFOUND)) as daysSinceDiscovery
,vh.exploitavailable
,vh.fismaseverity
,s.HVASTATUS
,IFF(bodcat.Is_Deleted = 0,'Yes','No') as is_bod
,s.IS_MARKETPLACE
,s.MEFSTATUS
,vh.MitigationStatus
,s.TLC_PHASE
,snap.REPORT_ID
from snap
join CORE.ASSETHIST ah on ah.REPORT_ID = snap.REPORT_ID -- 240806 CR946
join CORE.VULHIST vh on vh.REPORT_ID = snap.REPORT_ID and vh.DW_ASSET_ID = ah.DW_ASSET_ID -- 240806 CR946
join CORE.SYSTEMS s on s.system_id = ah.system_id -- 240806 CR946 Dont use view. As time moves on a system might be retired and we would not show the history
left join CORE.KEV_CATALOG bodcat on bodcat.CVE = vh.CVE
group by
snap.REPORT_ID
,s.SYSTEM_ID
,s.Component_Acronym
,ah.DATACENTER_ID
,vh.VUL_DATECREATED
,vh.datemitigated
,vh.exploitavailable
,vh.fismaseverity
,s.HVASTATUS
,bodcat.Is_Deleted
,s.IS_MARKETPLACE
,s.MEFSTATUS
,vh.MitigationStatus
,s.TLC_PHASE
)
select distinct
s.Acronym
,s.Component_Acronym
,coalesce(vh.cvecount,0) as "CVE Count" -- 241107 CR1026 add coalesce
,coalesce(vh.UniqueCVECount,0) as "Unique CVE Count" -- 241107 CR1026 add coalesce
,snap.CurrentMTDStart
,IFNULL(dc.datacenter_acronym,s.PRIMARY_OPERATING_LOCATION_ACRONYM) as data_center_name --Datacenter from assets or primary oploc.
,vh.datecreated
,vh.DATEMITIGATED
,vh.daysSinceDiscovery
,vh.exploitavailable
,vh.fismaseverity
,vh.HVASTATUS
,vh.is_bod
,vh.IS_MARKETPLACE
,vh.MEFSTATUS
,vh.MitigationStatus
,snap.MTDVSEOM -- 231106
,snap.PrevEOMStart
,snap.Rankk
,CURRENT_TIMESTAMP as refresh_date
,snap.REPORT_DATE
,snap.REPORT_ID
,vh.TLC_PHASE
,ss.VULNRISKTOLERANCE
FROM snap
join CORE.VW_SYSTEMSUMMARY ss on ss.REPORT_ID = snap.REPORT_ID
right join CORE.VW_SYSTEMS s on s.system_id = ss.system_id
left join (select a.system_id,a.datacenter_id,b.acronym as datacenter_acronym from
    (select distinct system_id, datacenter_id from CORE.VW_ASSETS --All datacenters for active assets.
    union
    select distinct system_id, datacenter_id from vulh) a  -- Datacenters for some inactive assets
    join CORE.VW_SYSTEMS b on a.datacenter_id = b.system_id
    ) dc on dc.system_id = s.system_id
left join vulh vh on vh.REPORT_ID = ss.REPORT_ID and vh.SYSTEM_ID = dc.SYSTEM_ID and vh.datacenter_id = dc.datacenter_id
;