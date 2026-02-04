create or replace view VW_RAW_HWAM_POPULATED_FIELDS(
	ASSET_ID_TATTOO,
	BIOS_GUID,
	DATACENTER_ID,
	FQDN,
	HOSTNAME,
	IPV4,
	IPV6,
	MACADDRESS,
	MOTHERBOARD,
	NETBIOSNAME,
	SYSTEM_ID,
	TOTAL
) as
SELECT DISTINCT
case coalesce(NULLIF(ASSET_ID_TATTOO,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as ASSET_ID_TATTOO
,case coalesce(NULLIF(ARRAY_TO_STRING(BIOS_GUID,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as BIOS_GUID
,case coalesce(NULLIF(DATACENTER_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as DATACENTER_ID
--,case coalesce(NULLIF(DW_ASSET_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as DW_ASSET_ID

,case coalesce(NULLIF(ARRAY_TO_STRING(FQDN,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as FQDN
,case coalesce(NULLIF(ARRAY_TO_STRING(HOSTNAME,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as HOSTNAME
,case coalesce(NULLIF(ARRAY_TO_STRING(IPV4,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as IPV4
,case coalesce(NULLIF(ARRAY_TO_STRING(IPV6,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as IPV6
,case coalesce(NULLIF(ARRAY_TO_STRING(MACADDRESS,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as MACADDRESS

,case coalesce(NULLIF(MOTHERBOARD,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as MOTHERBOARD
,case coalesce(NULLIF(ARRAY_TO_STRING(NETBIOSNAME,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as NETBIOSNAME
,case coalesce(NULLIF(SYSTEM_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as SYSTEM_ID
--,case coalesce(NULLIF(TENANT_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End as TENANT_ID
,COUNT(1) Total
FROM CORE.RAW_HWAM
WHERE SNAPSHOT_ID = 2260
--2260
--and TEST_DW_ASSET_ID = 0
GROUP BY 
case coalesce(NULLIF(ASSET_ID_TATTOO,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(ARRAY_TO_STRING(BIOS_GUID,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(DATACENTER_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
--,case coalesce(NULLIF(DW_ASSET_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End

,case coalesce(NULLIF(ARRAY_TO_STRING(FQDN,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(ARRAY_TO_STRING(HOSTNAME,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(ARRAY_TO_STRING(IPV4,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(ARRAY_TO_STRING(IPV6,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(ARRAY_TO_STRING(MACADDRESS,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End

,case coalesce(NULLIF(MOTHERBOARD,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(ARRAY_TO_STRING(NETBIOSNAME,','),''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
,case coalesce(NULLIF(SYSTEM_ID,''),'ITSNULL') when 'ITSNULL' then 'ITSNULL' Else 'Populated' End
;