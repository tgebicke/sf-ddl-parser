create or replace view V_SYSTEMSUMMARY_MCRR_MILESTONE(
	POAM_ID,
	LATESTMILESTONEUPDATEDATE,
	ACRONYM,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	WEAKNESS_RISK_LEVEL,
	OVERALL_STATUS,
	REPORTNAME
) COMMENT='Contains Milestone data details related to Systems (POA&M Risk Level / Milestone last updated)'
 as
SELECT  distinct m.POAM_ID
,cast(m.LAST_UPDATED as datetime) as LatestMilestoneUpdateDate
,S.Acronym
,s.Component_Acronym
,s.Group_Acronym
,p."Weakness_Risk_Level" Weakness_Risk_Level
,p."Overall_Status" Overall_Status
,reportName
FROM rpt.V_MILESTONE_MONTHENDSNAPSHOT m
INNER JOIN
(SELECT POAM_ID, MAX(cast (LAST_UPDATED as datetime)) AS LatestdateTime
FROM rpt.V_MILESTONE_MONTHENDSNAPSHOT
GROUP BY POAM_ID) drv_m
ON (m.POAM_ID = drv_m.POAM_ID
AND cast(m.LAST_UPDATED as datetime) = drv_m.LatestdateTime)
INNER JOIN (select "Weakness_Risk_Level", "Overall_Status", "POA&M ID", "Archer_Tracking_ID" from
rpt.V_POAMS_MONTHENDSNAPSHOT) P on (m.POAM_ID=P."POA&M ID")
INNER JOIN (select Archer_Tracking_ID, Acronym,Component_Acronym,Group_Acronym from CORE.VW_SYSTEMS) S
on S.Archer_Tracking_ID = P."Archer_Tracking_ID"
 LEFT JOIN rpt.CRR_Component_Params reportName ON ((Acronym = reportName.systems) AND (Component_Acronym = reportName.component) AND (Group_Acronym = reportName.groups))
where datediff(day,(select max(report_date) from core.VW_REPORTSNAPSHOTS where DataCategory = 'CFACTS' and Is_endOfMonth =1),cast(LAST_UPDATED as  datetime)) <-24
and P."Overall_Status" not in ('Closed for System Disposition','Completed','Pending Verification')
group by m.poam_id,cast(m.LAST_UPDATED as datetime),S.Acronym,s.Component_Acronym,s.Group_Acronym,Weakness_Risk_Level,Overall_Status, REPORTNAME;