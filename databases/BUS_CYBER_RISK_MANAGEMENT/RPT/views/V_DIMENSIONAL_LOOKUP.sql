create or replace view V_DIMENSIONAL_LOOKUP(
	ID,
	ACRONYM,
	ACR_ALIAS,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	TLC_PHASE,
	HVASTATUS,
	IS_MARKETPLACE,
	MEFSTATUS,
	OATO_CATEGORY
) COMMENT='FISMA System related hierarchy look up details'
 as
SELECT distinct 
s.SYSTEM_ID as ID, 
s.acronym, 
substring(s.Acronym, 1, 1) || '***' as Acr_Alias,
s.Component_Acronym, 
s.Group_Acronym, 
TLC_Phase, 
HVAStatus, 
Is_MarketPlace, 
MEFStatus,
OATO_Category
FROM CORE.VW_SYSTEMS s 
Where s.Component_Acronym not in ('Not specified','FCHCO','CMCHO');