create or replace view VW_DEVICETYPES(
	DEVICETYPE,
	DEVICEROLE,
	INSERT_DATE,
	IS_CANBETAGGEDWITHFISMAID,
	IS_WORKSTATIONORSERVER,
	TOTALASSETS
) COMMENT='Shows total assets by device types with device roles.'
 as
SELECT 
dt.DEVICETYPE
,dr.DeviceRole 
,dt.INSERT_DATE
,dt.Is_CanBeTaggedWithFismaID
,dt.Is_WorkstationOrServer
,coalesce(a.TotalAssets,0) as TotalAssets
FROM CORE.DeviceRoles dr
JOIN CORE.DeviceTypes dt on dt.DEVICEROLE = dr.DEVICEROLE
LEFT OUTER JOIN (select DEVICETYPE,count(1) as TotalAssets
	FROM CORE.VW_Assets 
	--where Is_Applicable = 1
	GROUP BY DEVICETYPE) a on a.DEVICETYPE = dt.DEVICETYPE
order by dt.DeviceType;