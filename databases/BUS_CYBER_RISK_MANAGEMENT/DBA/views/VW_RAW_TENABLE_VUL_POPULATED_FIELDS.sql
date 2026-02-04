create or replace view VW_RAW_TENABLE_VUL_POPULATED_FIELDS(
	ASSET_ID_TATTOO,
	DATACENTER_ID,
	DNSNAME,
	HOSTNAME,
	IP,
	MACADDRESS,
	NETBIOSNAME,
	REPOSITORY_ID,
	SYSTEM_ID,
	TENABLEUUID,
	TOTAL
) as
SELECT DISTINCT
case coalesce(NULLIF(ASSET_ID_TATTOO,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as ASSET_ID_TATTOO
,case coalesce(NULLIF(DATACENTER_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as DATACENTER_ID
--,case coalesce(NULLIF(DW_ASSET_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as DW_ASSET_ID

,case coalesce(NULLIF(DNSNAME,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as DNSNAME
,case coalesce(NULLIF(HOSTNAME,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as HOSTNAME
,case coalesce(NULLIF(IP,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as IP
,case coalesce(NULLIF(MACADDRESS,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as MACADDRESS

,case coalesce(NULLIF(NETBIOSNAME,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as NETBIOSNAME
,case coalesce(NULLIF(REPOSITORY_ID::varchar,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as REPOSITORY_ID
,case coalesce(NULLIF(SYSTEM_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as SYSTEM_ID
,case coalesce(NULLIF(TENABLEUUID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as TENABLEUUID
--,case coalesce(NULLIF(TENANT_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as TENANT_ID
,COUNT(1) Total
FROM CORE.RAW_TENABLE_VUL
WHERE SNAPSHOT_ID = 2263
--2264	AWS VUL MITIGATED
--2263

GROUP BY 
case coalesce(NULLIF(ASSET_ID_TATTOO,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(DATACENTER_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(DNSNAME,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(HOSTNAME,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(IP,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(MACADDRESS,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(NETBIOSNAME,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(REPOSITORY_ID::varchar,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(SYSTEM_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(TENABLEUUID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
;