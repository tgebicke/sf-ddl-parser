create or replace view VW_RAW_TENABLE_VUL_CASES(
	SNAPSHOT_ID,
	SNAPSHOT_DATE,
	DATACATEGORY,
	DATACENTER_ID,
	IP,
	MACADDRESS,
	DNSNAME,
	TENABLEUUID,
	NETBIOSNAME,
	PRIMARY_FISMA_ID_TATTOO,
	ASSET_ID_TATTOO,
	HOSTNAME,
	TOTAL
) COMMENT='Returns history of total raw tenable records based on diferrent cobination of fields (e.g. datacenter_id, IPv4) data provided or not. '
 as
SELECT 
snap.snapshot_id
,snap.snapshot_date::date as SNAPSHOT_DATE
,snap.datacategory
,case coalesce(NULLIF(r.DATACENTER_ID,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as DATACENTER_ID
,case coalesce(NULLIF(r.IP,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as IP
,case coalesce(NULLIF(r.MACADDRESS,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as MACADDRESS
,case coalesce(NULLIF(r.DNSNAME,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as DNSNAME
,case coalesce(NULLIF(r.TENABLEUUID,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as TENABLEUUID
,case coalesce(NULLIF(r.NETBIOSNAME,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as NETBIOSNAME
,case coalesce(NULLIF(r.PRIMARY_FISMA_ID_TATTOO,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as PRIMARY_FISMA_ID_TATTOO
,case coalesce(NULLIF(r.ASSET_ID_TATTOO,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as ASSET_ID_TATTOO
,case coalesce(NULLIF(r.HOSTNAME,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End as HOSTNAME
,count(1) Total
FROM CORE.RAW_TENABLE_VUL r
JOIN CORE.SNAPSHOT_IDS snap on snap.snapshot_id = r.snapshot_id
--WHERE r.temp_dw_asset_id = 0
--where r.compliance_check_name IS NOT NULL
--Where r.SNAPSHOT_ID = 250 and r.APPLICABILITYCODE <> 'Excluding AWS VUL from CCIC VUL FEED'
GROUP BY
snap.snapshot_id
,snap.snapshot_date::date -- SNAPSHOT_DATE
,snap.datacategory
,case coalesce(NULLIF(r.DATACENTER_ID,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- DATACENTER_ID
,case coalesce(NULLIF(r.IP,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- IP
,case coalesce(NULLIF(r.MACADDRESS,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- MACADDRESS
,case coalesce(NULLIF(r.DNSNAME,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- DNSNAME
,case coalesce(NULLIF(r.TENABLEUUID,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- TENABLEUUID
,case coalesce(NULLIF(r.NETBIOSNAME,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- NETBIOSNAME
,case coalesce(NULLIF(r.PRIMARY_FISMA_ID_TATTOO,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- PRIMARY_FISMA_ID_TATTOO
,case coalesce(NULLIF(r.ASSET_ID_TATTOO,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- ASSET_ID_TATTOO
,case coalesce(NULLIF(r.HOSTNAME,''),'ItsNull')
    when 'ItsNull' then '0'
    Else '1'
End -- HOSTNAME
ORDER BY snap.snapshot_date::date desc
,snap.snapshot_id desc
,snap.datacategory
,count(1) desc;