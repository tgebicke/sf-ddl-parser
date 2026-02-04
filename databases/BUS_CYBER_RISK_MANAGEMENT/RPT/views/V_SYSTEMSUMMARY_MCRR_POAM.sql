create or replace view V_SYSTEMSUMMARY_MCRR_POAM(
	ARCHER_TRACKING_ID,
	ACRONYM,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	DAYS_OPEN,
	WEAKNESS_RISK_LEVEL,
	POAM_ID,
	OVERALL_STATUS,
	REPORT_DATE,
	RANKK,
	REPORTNAME
) COMMENT='Contains POA&M data details related to Systems (POA&M Risk Level/POA&M ID/Weakness Score)'
 as
select ph.Archer_Tracking_ID
,Acronym
,Component_Acronym
,Group_Acronym
,days_open
,WEAKNESS_RISK_LEVEL
,poam_id
,OVERALL_STATUS
,a.report_date
,dense_rank()over(order by a.report_date desc) as rankk
  ,Report_Name.ReportName 
from core.VW_POAMHIST ph
join (select top 2 report_id, report_date, rank()over(order by report_date desc) as rankk from core.REPORT_IDS where is_endofmonth =1 
order by REPORT_DATE desc)a on a.report_id = ph.report_id
inner join (select Archer_Tracking_ID,Component_Acronym,Acronym,Group_Acronym from CORE.VW_SYSTEMS
where TLC_Phase<>'Retire')syst on (ph.Archer_Tracking_ID = syst.Archer_Tracking_ID)
LEFT JOIN 
  rpt.CRR_Component_Params Report_Name ON ((syst.Acronym = Report_Name.systems) AND (syst.Component_Acronym = Report_Name.COMPONENT) AND (syst.Group_Acronym = Report_Name.GROUPS))
where Overall_Status not in (
'Closed for System Retired'
,'Completed'
,'Pending Verification'
,'Risk Accepted'
);