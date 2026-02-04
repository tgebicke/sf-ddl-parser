create or replace view V_SYSTEMSUMMARY_DCRR_VULN(
	JOIN_ID,
	ACRONYM,
	ARCHER_TRACKING_ID,
	AUTH_DECISION,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	HVASTATUS,
	IN_CMS_CLOUD,
	ISSO_COUNT,
	OA_STATUS,
	MEFSTATUS,
	IS_MARKETPLACE,
	TLC_PHASE,
	UNIQ_CVE_COUNT,
	CVE_COUNT,
	FISMASEVERITY,
	LESSTHAN25,
	LESSTHAN50,
	GREATERTHAN50,
	GREATERTHAN75,
	CRITICALGT15,
	HIGHGT30,
	MODERATEGT90,
	LOWGT365,
	REPORTDATE
) COMMENT='Used for Tableau in Dynamic Cyber Risk Dashboard : \nView contains vuln related information(CVE count, Fisma Severity)'
 as
 with
ReportIDs as ((select Report_ID,Report_Date, snapshot_ID, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date,Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where DataCategory= 'HWAM')a where rankkForSnap =1
	union --CR#822 changed Union All to Union to avoid duplicate records on monthend snapshot date
	select Report_ID,Report_Date, snapshot_ID, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date, Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where Is_endOfMonth =1 and DataCategory= 'HWAM')a where rankkForSnap = 1)),  
Snapshots as (select Report_ID,Report_Date, snapshot_ID,Is_endOfMonth from ReportIDs r)
select s.system_id as join_ID
,acronym
,Archer_Tracking_ID
,auth_decision
,Component_Acronym
,Group_Acronym
,HVAStatus
,In_CMS_Cloud
,isso_count
,OA_Status
,MEFStatus
,Is_MarketPlace
,tlc_phase
,Uniq_cve_count
,cve_count
,FISMAseverity
,LessThan25
,LessThan50
,GreaterThan50
,GreaterThan75
,CriticalGT15
,HighGT30
,ModerateGT90
,LowGT365
,Report_Date ReportDate
from CORE.VW_SYSTEMS s
right outer JOIN (select system_id, Report_ID from CORE.VW_SYSTEMSUMMARY) ss on ss.system_id = s.system_id
join Snapshots snap on snap.Report_ID = ss.Report_ID
left outer join (select system_id,count(distinct cve) Uniq_cve_count, count(cve) cve_count, FISMAseverity, Report_ID from CORE.VW_VULHIST where MitigationStatus in ('open', 'reopened')
group by system_id, FISMAseverity, Report_ID) vul on vul.system_id = ss.system_id and 
vul.Report_ID = snap.Report_ID
--Below lines are added for CR #959
left join (select system_id, sum(Q2) + sum(Q3) as LessThan25,sum(Q4) as LessThan50, sum(Q5) as GreaterThan50, sum(Q6) as GreaterThan75 from (SELECT system_id, 
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
    ) where lower(MitigationStatus) in ('open', 'reopened')) group by system_id)vulcur on ss.system_id = vulcur.system_id  
 left join (select system_id, sum(Q1) CriticalGT15,sum(Q2) as HighGT30, sum(Q3) as ModerateGT90, sum(Q4) as LowGT365 from (SELECT system_id, 
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
    )where lower(MitigationStatus) in ('open', 'reopened'))  group by system_id)vulDays on ss.system_id = vulDays.system_id
  ;