create or replace view VW_HRS_POAM(
	COMPONENT_ACRONYM,
	ACRONYM,
	ARCHER_TRACKING_ID,
	AUTH_DECISION,
	AVG_DAYS_OPEN,
	WEAKNESS_RISK_LEVEL
) COMMENT='Contains summarized POAM related metrics data'
 as
SELECT  Component_Acronym ,Acronym,syst.Archer_Tracking_ID,Auth_Decision,(cast(days_open as numeric)) as avg_days_open,weakness_risk_level
FROM	CORE.VW_SYSTEMS syst
		left outer join CORE.VW_POAMS poam 
		on (syst.Archer_Tracking_ID =poam.archer_tracking_id 
		and Poam.overall_status in ('Delayed','Ongoing','Draft')
		and  weakness_risk_level in ('Critical','High','Low','Moderate'))
where	Component_Acronym IS NOT NULL
		and syst.TLC_Phase = 'Operate';