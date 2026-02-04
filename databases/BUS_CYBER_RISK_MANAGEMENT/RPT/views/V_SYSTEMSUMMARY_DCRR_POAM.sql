create or replace view V_SYSTEMSUMMARY_DCRR_POAM(
	ACRONYM,
	CFACTS_UID,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	HVASTATUS,
	IS_MARKETPLACE,
	MEFSTATUS,
	TLC_PHASE,
	WEAKNESS_RISK_LEVEL,
	REPORTDATE,
	WEAKNESS_WEIGHT,
	POAM_CNT
) COMMENT='Used for Tableau in Dynamic Cyber Risk Dashboard : \nView contains POAM related information(POAM count, Weakness Risk Level)'
 as
select distinct
Acronym, 
p.system_id CFACTS_UID,
s.Component_Acronym
,s.Group_Acronym
,s.HVAStatus
,s.Is_MarketPlace
,s.MEFStatus
,s.TLC_Phase
,WEAKNESS_RISK_LEVEL as Weakness_Risk_Level
,reportdate as reportdate
,case when WEAKNESS_RISK_LEVEL= 'Low' then 10
when (WEAKNESS_RISK_LEVEL)= 'Moderate' then 15
when (WEAKNESS_RISK_LEVEL)= 'High' then 30
when (WEAKNESS_RISK_LEVEL)= 'Critical' then 45 else 0 end weakness_weight,
count(distinct POAM_ID) as POAM_CNT
from CORE.VW_POAMS_OPEN p --CR#1074
join CORE.VW_SYSTEMS s on p.system_id = s.system_id 
group by ALL;