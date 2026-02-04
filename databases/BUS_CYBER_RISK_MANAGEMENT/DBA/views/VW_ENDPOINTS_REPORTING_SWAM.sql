create or replace view VW_ENDPOINTS_REPORTING_SWAM(
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
	TOTAL_WINDOWS_ENDPOINTS,
	TOTAL_WINDOWS_ENDPOINTS_WITH_SWAM,
	ASSETS_NOT_REPORTING_SWAM,
	TOTAL_ENDPOINTS_CREDENTIALED
) COMMENT='Visibility of Endpoints Reporting SWAM\t'
 as
with
WindowsEndpoints as (select dw_asset_id from core.vw_assets where upper(os) like '%WINDOWS%' and is_endpoint = 1)
,AssetSwam as (select distinct wep.dw_asset_id
    from WindowsEndpoints wep
    join core.ASSET_SOFTWARE soft on soft.dw_asset_id = wep.dw_asset_id
)
,DCSYS as (select a.datacenter_acronym,a.system_acronym,count(1) TOTAL_WINDOWS_ENDPOINTS
    from WindowsEndpoints wep
    join core.vw_assets a on a.dw_asset_id = wep.dw_asset_id
    group by a.datacenter_acronym,a.system_acronym
)
,DCSYS_ASSETS_WT_SWAM as (select a.datacenter_acronym,a.system_acronym,count(1) TOTAL_WINDOWS_ENDPOINTS_WITH_SWAM
    from AssetSwam aswam
    join core.vw_assets a on a.dw_asset_id = aswam.dw_asset_id
    group by a.datacenter_acronym,a.system_acronym    
)
,DCSYS_ASSETS_CREDENTIALED as (select a.datacenter_acronym,a.system_acronym,count(1) TOTAL_ENDPOINTS_CREDENTIALED
    from WindowsEndpoints wep
    join core.vw_assets a on a.dw_asset_id = wep.dw_asset_id
    where a.IS_TENABLE_CREDENTIALED_SCAN = 1
    group by a.datacenter_acronym,a.system_acronym
)
select ds.DATACENTER_ACRONYM,ds.SYSTEM_ACRONYM,ds.TOTAL_WINDOWS_ENDPOINTS,coalesce(dcswam.TOTAL_WINDOWS_ENDPOINTS_WITH_SWAM,0) as TOTAL_WINDOWS_ENDPOINTS_WITH_SWAM
,(ds.TOTAL_WINDOWS_ENDPOINTS - coalesce(dcswam.TOTAL_WINDOWS_ENDPOINTS_WITH_SWAM,0)) as ASSETS_NOT_REPORTING_SWAM
,coalesce(cred.TOTAL_ENDPOINTS_CREDENTIALED,0) as TOTAL_ENDPOINTS_CREDENTIALED
FROM DCSYS ds
LEFT OUTER JOIN DCSYS_ASSETS_CREDENTIALED cred on cred.datacenter_acronym = ds.datacenter_acronym and cred.system_acronym = ds.system_acronym
LEFT OUTER JOIN DCSYS_ASSETS_WT_SWAM dcswam on dcswam.datacenter_acronym = ds.datacenter_acronym and dcswam.system_acronym = ds.system_acronym
order by ds.datacenter_acronym,ds.system_acronym;