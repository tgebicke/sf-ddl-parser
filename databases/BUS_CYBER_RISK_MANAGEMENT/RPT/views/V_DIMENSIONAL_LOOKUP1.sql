create or replace view V_DIMENSIONAL_LOOKUP1(
	ID,
	DCID,
	ACRONYM,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	TLC_PHASE,
	HVASTATUS,
	IS_MARKETPLACE,
	MEFSTATUS,
	OATO_CATEGORY,
	DATACENTER_ACRONYM
) COMMENT='FISMA System related hierarchy look up details'
 as
SELECT distinct 
s.SYSTEM_ID as ID, 
dc.SYSTEM_ID as DCID, 
s.acronym, 
s.Component_Acronym, 
s.Group_Acronym, 
s.TLC_Phase, 
s.HVAStatus, 
s.Is_MarketPlace, 
s.MEFStatus,
s.OATO_Category,
IFNULL(dc.Acronym, s.primary_operating_location_acronym) as datacenter_acronym
FROM CORE.VW_Systems s  
left outer JOIN CORE.VW_assets a on a.SYSTEM_ID = s.SYSTEM_ID 
left outer JOIN CORE.VW_Systems DC on DC.SYSTEM_ID = a.datacenter_id
Where s.Component_Acronym not in ('Not specified','FCHCO','CMCHO');