create or replace view V_CYBERRISK_SYSTEM_DEVICES(
	GROUP_ACRONYM,
	COMPONENT_ACRONYM,
	"System",
	ACRONYM,
	TLC_PHASE,
	DEVICETYPE,
	TOTALASSETS,
	DATACENTER_ID,
	PRIMARY_FISMA_ID
) COMMENT='Used in other views to get the Asset details'
 as
select 
s.Group_Acronym 
,s.Component_Acronym 
,s.Acronym as "System"
,dc.Acronym
,s.TLC_Phase
,dt.DeviceType
,coalesce(sa.TotalAssets,0) as TotalAssets
,dc.SYSTEM_ID as datacenter_id
,s.SYSTEM_ID as primary_fisma_id
FROM (select a.DATACENTER_ID,a.SYSTEM_ID,a.DEVICETYPE,COUNT(1) TotalAssets
	FROM CORE.VW_Assets a
	GROUP BY a.DATACENTER_ID,a.SYSTEM_ID,a.DEVICETYPE) sa 
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = sa.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = sa.SYSTEM_ID
JOIN CORE.DEVICETYPES dt on dt.DEVICETYPE = sa.DEVICETYPE
order by dc.Acronym
,s.Acronym 
,dt.DeviceType
;