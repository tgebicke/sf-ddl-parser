create or replace view VW_ASSETAGE_BYDEVICETYPE(
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
	DEVICETYPE,
	ASSETS_BT0AND3,
	ASSETS_BT0AND7,
	ASSETS_BT4AND30,
	ASSETS_BT31AND90,
	ASSETS_GT90,
	ASSETS_VULBT0AND3,
	ASSETS_VULBT0AND7,
	ASSETS_VULBT4AND30,
	ASSETS_VULBT31AND90,
	ASSETS_VULGT90
) COMMENT='Shows total assets of multiple age group based on last_confirmed_time and Lastseen_VUL group by devicetype.'
 as
select dc.DataCenter_Acronym
,dc.System_Acronym
,dc.DeviceType
,coalesce(bt0and3.TotalAssets,0) as Assets_bt0and3
,coalesce(bt0and7.TotalAssets,0) as Assets_bt0and7
,coalesce(bt4and30.TotalAssets,0) as Assets_bt4and30
,coalesce(bt31and90.TotalAssets,0) as Assets_bt31and90
,coalesce(gt90.TotalAssets,0) as Assets_gt90
,coalesce(Vulbt0and3.TotalAssets,0) as Assets_Vulbt0and3
,coalesce(Vulbt0and7.TotalAssets,0) as Assets_Vulbt0and7
,coalesce(Vulbt4and30.TotalAssets,0) as Assets_Vulbt4and30
,coalesce(Vulbt31and90.TotalAssets,0) as Assets_Vulbt31and90
,coalesce(Vulgt90.TotalAssets,0) as Assets_Vulgt90

FROM (SELECT DataCenter_Acronym,System_Acronym,DeviceType
	FROM CORE.VW_Assets
	group by DataCenter_Acronym,System_Acronym,DeviceType) dc

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,last_confirmed_time,getdate()) between 0 and 3
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) bt0and3 on bt0and3.DataCenter_Acronym = dc.DataCenter_Acronym and bt0and3.System_Acronym = dc.System_Acronym and bt0and3.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,last_confirmed_time,getdate()) between 0 and 7
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) bt0and7 on bt0and7.DataCenter_Acronym = dc.DataCenter_Acronym and bt0and7.System_Acronym = dc.System_Acronym and bt0and7.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,last_confirmed_time,getdate()) between 4 and 30
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) bt4and30 on bt4and30.DataCenter_Acronym = dc.DataCenter_Acronym and bt4and30.System_Acronym = dc.System_Acronym and bt4and30.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,last_confirmed_time,getdate()) between 31 and 90
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) bt31and90 on bt31and90.DataCenter_Acronym = dc.DataCenter_Acronym and bt31and90.System_Acronym = dc.System_Acronym and bt31and90.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets 
	FROM CORE.VW_Assets
	where DATEDIFF(d,last_confirmed_time,getdate()) > 90
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) gt90 on gt90.DataCenter_Acronym = dc.DataCenter_Acronym and gt90.System_Acronym = dc.System_Acronym and gt90.DeviceType = dc.DeviceType
------------------------------------------------------------------------------------------------------------------------------
LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,Lastseen_VUL,getdate()) between 0 and 3
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) Vulbt0and3 on Vulbt0and3.DataCenter_Acronym = dc.DataCenter_Acronym and Vulbt0and3.System_Acronym = dc.System_Acronym and Vulbt0and3.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,last_confirmed_time,getdate()) between 0 and 7
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) Vulbt0and7 on Vulbt0and7.DataCenter_Acronym = dc.DataCenter_Acronym and Vulbt0and7.System_Acronym = dc.System_Acronym and Vulbt0and7.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,Lastseen_VUL,getdate()) between 4 and 30
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) Vulbt4and30 on Vulbt4and30.DataCenter_Acronym = dc.DataCenter_Acronym and Vulbt4and30.System_Acronym = dc.System_Acronym and Vulbt4and30.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets
	FROM CORE.VW_Assets
	where DATEDIFF(d,Lastseen_VUL,getdate()) between 31 and 90
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) Vulbt31and90 on Vulbt31and90.DataCenter_Acronym = dc.DataCenter_Acronym and Vulbt31and90.System_Acronym = dc.System_Acronym and Vulbt31and90.DeviceType = dc.DeviceType

LEFT OUTER JOIN (SELECT DataCenter_Acronym,System_Acronym,DeviceType,count(1) TotalAssets 
	FROM CORE.VW_Assets
	where DATEDIFF(d,Lastseen_VUL,getdate()) > 90
	group by DataCenter_Acronym
	,System_Acronym,DeviceType) Vulgt90 on Vulgt90.DataCenter_Acronym = dc.DataCenter_Acronym and Vulgt90.System_Acronym = dc.System_Acronym and Vulgt90.DeviceType = dc.DeviceType

order by dc.DataCenter_Acronym
,dc.System_Acronym
,dc.DeviceType;