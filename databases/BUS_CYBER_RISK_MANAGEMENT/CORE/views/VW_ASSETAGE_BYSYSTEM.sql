create or replace view VW_ASSETAGE_BYSYSTEM(
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
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
) COMMENT='Shows multiple age groups total assets of systems, based on last_confirmed_time and Lastseen_VUL .'
 as
select DataCenter_Acronym
,System_Acronym
,SUM(Assets_bt0and3) as Assets_bt0and3
,SUM(Assets_bt0and7) as Assets_bt0and7
,SUM(Assets_bt4and30) as Assets_bt4and30
,SUM(Assets_bt31and90) as Assets_bt31and90
,SUM(Assets_gt90) as Assets_gt90
,SUM(Assets_Vulbt0and3) as Assets_Vulbt0and3
,SUM(Assets_Vulbt0and7) as Assets_Vulbt0and7
,SUM(Assets_Vulbt4and30) as Assets_Vulbt4and30
,SUM(Assets_Vulbt31and90) as Assets_Vulbt31and90
,SUM(Assets_Vulgt90) as Assets_Vulgt90
FROM CORE.VW_AssetAge_ByDeviceType
group by DataCenter_Acronym
,System_Acronym
order by DataCenter_Acronym
,System_Acronym;