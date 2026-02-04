create or replace view V_MILESTONEUPDATE_MONTHLY(
	"POA&M ID",
	"POA&M ID#",
	LATESTMILESTONEUPDATEDATE,
	SCHEDULED_COMPLETION_DATE,
	OVERALL_STATUS,
	WEAKNESS_RISK_LEVEL,
	SYSACRONYM,
	POAMCOUNT,
	ACRONYM,
	DAYS_OPEN,
	TLC_PHASE,
	COMPONENT_ACRONYM
) COMMENT='Updated Milestone data for the month end snapshot'
 as
select  
drv1.POAM_ID as "POA&M ID",  
substring(drv1.POAM_ID,CHARINDEX('-',drv1.POAM_ID) + 1, LEN(drv1.POAM_ID)-CHARINDEX('-', drv1.POAM_ID)) as "POA&M ID#",  
drv1.LatestMilestoneUpdateDate, 
drv1.Scheduled_Completion_Date,
drv1.Overall_Status,
drv1.Weakness_Risk_Level,
case when drv1.POAM_ID is NULL then NULL else s.Acronym end as SysAcronym,
case when drv1.POAM_ID is NULL then NULL else 1 end as POAMCount,
s.Acronym,
drv1.Days_Open, 
S.TLC_Phase,
s.component_acronym
from CORE.VW_Systems s
Left outer join
(select drv.* from
 
    (SELECT distinct m.POAM_ID,Last_Updated LatestMilestoneUpdateDate,P.Scheduled_Completion_Date,P.Overall_Status,P.Weakness_Risk_Level,P.Days_Open,P.SYSTEM_ID
	    FROM rpt.V_Milestone_MonthEndSnapshot m
        INNER JOIN (SELECT POAM_ID, MAX(Last_Updated) AS LatestdateTime 
            FROM rpt.V_Milestone_MonthEndSnapshot m GROUP BY POAM_ID) drv_m on m.POAM_ID = drv_m.POAM_ID AND m.Last_Updated = drv_m.LatestdateTime	
        INNER JOIN (select "POA&M ID" as POAM_ID,"Overall_Status" as OVERALL_STATUS,"Weakness_Risk_Level" as WEAKNESS_RISK_LEVEL,"Days_Open" as DAYS_OPEN,"CFACTS_UID" as SYSTEM_ID,"Scheduled_Completion_Date" as SCHEDULED_COMPLETION_DATE from rpt.V_POAMS_MonthEndSnapshot) P on m.POAM_ID = P.POAM_ID
	 where datediff(day,LAST_DAY(ADD_MONTHS(current_date(),-1)),Last_Updated::datetime) < -24 and P.Overall_Status not in ('Closed for System Disposition','Completed','Pending Verification')
	group by m.POAM_ID,Last_Updated,p.Scheduled_Completion_Date,Overall_Status,Weakness_Risk_Level,Days_Open,p.SYSTEM_ID
    order by
      CASE Weakness_Risk_Level
        WHEN 'High' THEN 1
        WHEN 'Moderate' THEN 2
        WHEN 'Low' THEN 3
        WHEN 'Not Rated' THEN 4
        ELSE 5
       END 
       ASC, Days_Open DESC
        --  OFFSET 0 ROWs
 	) drv
) drv1 on drv1.SYSTEM_ID = s.SYSTEM_ID;