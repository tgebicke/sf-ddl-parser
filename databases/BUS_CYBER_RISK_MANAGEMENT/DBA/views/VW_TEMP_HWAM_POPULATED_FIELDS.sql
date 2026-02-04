create or replace view VW_TEMP_HWAM_POPULATED_FIELDS(
	DATACATEGORY,
	CMR_DW_ASSET_ID,
	DW_ASSET_ID,
	ASSET_ID_TATTOO,
	NORMALIZED_FQDN,
	NORMALIZED_HOSTNAME,
	IPV4,
	NORMALIZED_MACADDRESS,
	MOTHERBOARD,
	NORMALIZED_NETBIOSNAME,
	SYSTEM_ACRONYM
) COMMENT='Diagnostic View that shows all fields in TEMP_HWAM table that are populated\t'
 as
SELECT
snap.datacategory
,case coalesce(cmr_dw_asset_id::varchar,'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End as CMR_DW_ASSET_ID,
case coalesce(dw_asset_id::varchar,'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End as DW_ASSET_ID
,case coalesce(NULLIF(th.ASSET_ID_TATTOO,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End as ASSET_ID_TATTOO
--,case coalesce(NULLIF(dc.ACRONYM,''),'ITSNULL')
--    when 'ITSNULL' then 'ITSNULL'
--    Else 'Populated'
--End as DATACENTER_ACRONYM
,case coalesce(NULLIF(th.NORMALIZED_FQDN,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End as NORMALIZED_FQDN
,case array_size(th.NORMALIZED_HOSTNAME) 
    when 0 then 'ITSNULL'
    Else 'Populated'
End as NORMALIZED_HOSTNAME
,case array_size(th.IPV4) 
    when 0 then 'ITSNULL'
    Else 'Populated'
End as IPV4
,case array_size(th.NORMALIZED_MACADDRESS) 
    when 0 then 'ITSNULL'
    Else 'Populated'
End as NORMALIZED_MACADDRESS
,case coalesce(NULLIF(th.MOTHERBOARD,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End as MOTHERBOARD
,case coalesce(NULLIF(th.NORMALIZED_NETBIOSNAME,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End as NORMALIZED_NETBIOSNAME
,case coalesce(NULLIF(s.ACRONYM,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End as SYSTEM_ACRONYM
FROM CORE.TEMP_HWAM th
join CORE.SNAPSHOT_IDS snap on snap.snapshot_id = th.snapshot_id
LEFT OUTER JOIN CORE.SYSTEMS dc on dc.SYSTEM_ID = th.datacenter_id
LEFT OUTER JOIN CORE.SYSTEMS s on s.SYSTEM_ID = th.SYSTEM_ID
/*
group by 
--snap.datacategory
case coalesce(NULLIF(th.ASSET_ID_TATTOO,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End
--,case coalesce(NULLIF(dc.ACRONYM,''),'ITSNULL')
--    when 'ITSNULL' then 'ITSNULL'
--    Else 'Populated'
--End
,case coalesce(NULLIF(th.NORMALIZED_FQDN,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End
,case array_size(th.NORMALIZED_HOSTNAME) 
    when 0 then 'ITSNULL'
    Else 'Populated'
End
,case array_size(th.IPV4) 
    when 0 then 'ITSNULL'
    Else 'Populated'
End
,case array_size(th.NORMALIZED_MACADDRESS) 
    when 0 then 'ITSNULL'
    Else 'Populated'
End
,case coalesce(NULLIF(th.MOTHERBOARD,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End
,case coalesce(NULLIF(th.NORMALIZED_NETBIOSNAME,''),'ITSNULL')
    when 'ITSNULL' then 'ITSNULL'
    Else 'Populated'
End
--,case coalesce(NULLIF(s.ACRONYM,''),'ITSNULL')
--    when 'ITSNULL' then 'ITSNULL'
--    Else 'Populated'
--End
*/
;