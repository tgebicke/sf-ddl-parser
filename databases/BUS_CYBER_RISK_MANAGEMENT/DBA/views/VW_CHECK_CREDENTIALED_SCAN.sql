create or replace view VW_CHECK_CREDENTIALED_SCAN(
	DW_ASSET_ID,
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
	LASTSEEN_VUL,
	IS_TENABLE_CREDENTIALED_SCAN,
	PRESENCE_OF_PLUGIN,
	IS_WORD_CREDENTIALED_PRESENT_IN_PLUGINTEXT,
	RAW_CREDENTIALED_CHECK_VALUE,
	RAW_CREDENTIALED_SCAN_VALUE,
	OS,
	PLUGINTEXT
) COMMENT='Check integrity of Asset.is_tenable_credentialed_scan'
 as
select a.dw_asset_id,a.DATACENTER_ACRONYM,a.SYSTEM_ACRONYM,a.lastseen_vul::date as LASTSEEN_VUL
,a.is_tenable_credentialed_scan
,case coalesce(plug.dw_asset_id,0)
    when 0 THEN 'Plugin19506Notfound'
    else 'See_Raw_Credentialed_Scan_Value'
end as Presence_of_plugin
,plug.IS_WORD_CREDENTIALED_PRESENT_IN_PLUGINTEXT
,plug.Raw_Credentialed_Check_Value
,plug.Raw_Credentialed_Scan_Value
,a.os,plug.plugintext
FROM CORE.VW_ASSETS a
LEFT OUTER JOIN (select r.dw_asset_id,snap.snapshot_date::date as snapshot_date,r.ip
,CASE position('CREDENTIAL',upper(r.plugintext)) 
    when 0 then 'No'
    Else 'Yes'
END IS_WORD_CREDENTIALED_PRESENT_IN_PLUGINTEXT
,position('Credentialed checks',r.plugintext) as Startof_Credentialed_Check
,split_part(split_part(substring(r.plugintext,Startof_Credentialed_Check,50),char(10),1),':',2) as Raw_Credentialed_Check_Value
,position('Credentialed_Scan',r.plugintext) as Startof_Credentialed_Scan
,REPLACE(split_part(split_part(substring(r.plugintext,Startof_Credentialed_Scan,50),char(10),1),':',2),'LastAuthenticatedResults','') as Raw_Credentialed_Scan_Value
--,Raw_Credentialed_Scan_Value::boolean as Raw_IS_Credentialed_Scan
,r.plugintext
FROM CORE.RAW_TENABLE_VUL r
JOIN CORE.SNAPSHOT_IDS snap on snap.snapshot_id = r.snapshot_id
where r.plugin_id = '19506' and snap.snapshot_date::date >= (current_date() - 15)::date ) plug on plug.dw_asset_id = a.dw_asset_id and plug.snapshot_date = a.lastseen_vul::date
;