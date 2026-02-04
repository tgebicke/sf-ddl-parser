create or replace view V_MONTHLY_CRR_VULNCOUNT(
	ACRONYM,
	COMPONENT_ACRONYM,
	FISMASEVERITY,
	GROUP_ACRONYM,
	UNIQ_CNT,
	BUCKETS,
	DELETIONREASON,
	TOT_CNT
) COMMENT='Not using in tableau'
 as
select 
s.acronym
,s.Component_Acronym
,FISMAseverity
,s.Group_Acronym
,count(distinct v.cve) uniq_cnt
,v.buckets
,null as DeletionReason
,count(v.CVE) tot_cnt
from CORE.VW_SYSTEMS s

left outer join (select 
    SYSTEM_ID
    ,cve
    --,DaysSinceDiscovery
    --,MitigationStatus
    ,FISMAseverity
    --,r.REPORT_DATE as snapshotdate
    ,DW_VUL_ID
    --,FK_AssetID
    ,case 
        when FISMAseverity = 'Critical' and DaysSinceDiscovery >15 and  DaysSinceDiscovery <=60 then 'Unique Critical >15 and <=60 Days'
        when FISMAseverity = 'Critical' and DaysSinceDiscovery >60  then 'Unique Critical >60 Days'
        when FISMAseverity = 'High' and DaysSinceDiscovery >30 and  DaysSinceDiscovery <=60 then 'Unique High >30 and <=60 Days'
        when FISMAseverity = 'High' and DaysSinceDiscovery >60 then 'Unique High >60 Days'
    end as buckets 
    from TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) r
    JOIN CORE.VW_VULHIST vh on vh.REPORT_ID = r.REPORT_ID
    where vh.FISMAseverity is not null and vh.MitigationStatus in ('open','reopened')) v on v.SYSTEM_ID = s.SYSTEM_ID
    
--left outer join (select id,datemitigated,DeletionReason,datecreated from dbo.VulMaster where DeletionReason is null) vm on (vm.ID = v.DW_VUL_ID)
--left outer join CORE.VW_ASSETHIST ah on ah,REPORT_ID = r.REPORT_ID and ah.DW_ASSET_ID = v.DW_ASSET_ID

WHERE s.TLC_PHASE <> 'Retire' and s.Component_Acronym not in ('Not specified','FCHCO','CMCHO')
group by s.acronym,s.Component_Acronym,FISMAseverity, s.Group_Acronym,buckets
;