create or replace view VW_SYSTEMS_REPORTED(
	ACRONYM,
	COMMONNAME,
	COMPONENT_ACRONYM,
	COLORCODE,
	LEGENDVALUE,
	PRIORITY,
	STATUS,
	LEGENDCOMMENT,
	IS_IN_REF_LOOKUPS_CAMP,
	LASTSEEN_HWAM,
	LASTSEEN_VUL,
	PRIMARY_OPERATING_LOCATION,
	PRIMARY_OPERATING_LOCATION_ACRONYM,
	PRIMARY_OPERATING_LOCATION_ID,
	SYSTEM_ID,
	TLC_PHASE,
	ASSETS,
	SCANNABLEASSETS,
	ASSETSSCANNED,
	SCANNABLE_BUT_NOT_SCANNED,
	ASSETS_NEVER_SCANNED,
	IS_DRAAS_SYSTEM,
	IS_SECOPS_TAGGED,
	CCSQ_REPOSITORY_ID_ARRAY,
	VULMASTER_REPOSITORY_ID_ARRAY,
	TERESA_WORKSHEET,
	TERESA_COMMENT,
	ELLIOT_COMMENT
) COMMENT='Diagnostic; View reports FISMA systems reporting or not reporting HWAM/VUL\t'
 as
SELECT
s.ACRONYM
,c.COMMONNAME
,s.COMPONENT_ACRONYM
,sc.colorcode
,sc.legendvalue
,sc.priority
,sc.status
,sc.legendcomment
,case coalesce(ref.VERIFIED_FISMA,'ITSNULL')
    when 'ITSNULL' then 'No'
    Else 'Yes'
end as IS_IN_REF_LOOKUPS_CAMP

,recent.LASTSEEN_HWAM
,recent.LASTSEEN_VUL

,s.PRIMARY_OPERATING_LOCATION
,pol.ACRONYM as PRIMARY_OPERATING_LOCATION_ACRONYM
,s.PRIMARY_OPERATING_LOCATION_ID

,s.SYSTEM_ID
,s.TLC_PHASE

,coalesce(a.ASSETS,0) as ASSETS

,coalesce(sa.ScannableAssets,0) as ScannableAssets -- 240426
,coalesce(va.AssetsScanned,0) as AssetsScanned -- 240426
,(coalesce(sa.ScannableAssets,0) - coalesce(va.AssetsScanned,0)) as Scannable_but_not_Scanned -- 240426

,coalesce(neverScanned.Assets_Never_Scanned,0) Assets_Never_Scanned
--240426
,case coalesce(draas.system_id,'ITSNULL')
    when 'ITSNULL' then 'No'
    Else 'Yes'
end as IS_DRAAS_SYSTEM

--240430
,case coalesce(secops.fisma_uuid,'ITSNULL')
    when 'ITSNULL' then 'No'
    Else 'Yes'
end as IS_SECOPS_TAGGED

,ccsq_repos.REPOSITORY_ID_ARRAY as CCSQ_REPOSITORY_ID_ARRAY -- 240426
,vul_repos.REPOSITORY_ID_ARRAY as VULMASTER_REPOSITORY_ID_ARRAY -- 240426
,coalesce(sc.teresa_worksheet_240426,sc.teresa_worksheet_240212) as TERESA_WORKSHEET
,coalesce(sc.teresa_comment_240426,sc.teresa_comment_240212) as TERESA_COMMENT
,sc.ELLIOT_COMMENT_240212 as ELLIOT_COMMENT
FROM CORE.SYSTEMS s
LEFT OUTER JOIN CORE.SYSTEM_COMMONNAME c on c.SYSTEM_ID = s.SYSTEM_ID
LEFT OUTER JOIN CORE.SYSTEMS pol on pol.SYSTEM_ID = s.PRIMARY_OPERATING_LOCATION_ID
LEFT OUTER JOIN DBA.SYSTEM_COMMENTS sc on sc.SYSTEM_ID = s.SYSTEM_ID

LEFT OUTER JOIN (SELECT DISTINCT VERIFIED_FISMA FROM CORE.VW_AWS_CAMPDB_LOOKUP) ref on ref.VERIFIED_FISMA = s.SYSTEM_ID -- 240603

LEFT OUTER JOIN (select SYSTEM_ID,count(1) Assets FROM CORE.ASSET where Is_Applicable = 1 group by SYSTEM_ID) a on a.SYSTEM_ID = s.SYSTEM_ID

LEFT OUTER JOIN (select SYSTEM_ID,count(1) Assets_Never_Scanned FROM CORE.ASSET where Is_Applicable = 1 and LASTSEEN_VUL IS NULL group by SYSTEM_ID) neverScanned on neverScanned.SYSTEM_ID = s.SYSTEM_ID

LEFT OUTER JOIN (select SYSTEM_ID,MAX(LASTSEEN_HWAM)::date as LASTSEEN_HWAM, MAX(LASTSEEN_VUL)::date as LASTSEEN_VUL FROM CORE.ASSET group by SYSTEM_ID) recent on recent.SYSTEM_ID = s.SYSTEM_ID

-- 240426
left outer join (select system_id,count(1) ScannableAssets from core.vw_assets where is_scannable = 1 group by system_id) sa on sa.system_id = s.system_id
-- 240426
left outer join (select a.system_id,count(1) AssetsScanned
    from core.vw_assets a
    join (select distinct dw_asset_id from core.vw_vulmaster) vm on vm.dw_asset_id = a.dw_asset_id group by a.system_id) va on va.system_id = s.system_id

-- 240426
left outer join (select CFACTS_UID, listagg(DISTINCT REPOSITORY_ID, ', ') WITHIN GROUP (ORDER BY REPOSITORY_ID ASC) as REPOSITORY_ID_ARRAY FROM REF_LOOKUPS.SHARED.SEC_MV_CCSQ_FISMA_LOOKUP GROUP BY CFACTS_UID) ccsq_repos on ccsq_repos.CFACTS_UID = s.system_id
-- 240426
LEFT OUTER JOIN (select distinct system_id from core.vw_assets where datacenter_id = '441a2d4fdbfbab00560cf9531f961911') as draas on draas.system_id = s.system_id -- DRaaS-CACHE
-- 240426
left outer join (select SYSTEM_ID, listagg(DISTINCT REPOSITORY_ID, ', ') WITHIN GROUP (ORDER BY REPOSITORY_ID::number ASC) as REPOSITORY_ID_ARRAY 
    FROM core.VW_VULMASTER GROUP BY SYSTEM_ID) vul_Repos on vul_Repos.system_id = s.system_id

-- 240430
LEFT OUTER JOIN (select distinct fisma_uuid from core.raw_hwam where fisma_uuid is not null) secops on secops.fisma_uuid = s.system_id
    
WHERE s.IS_PHANTOMSYSTEM = 0 and (upper(s.TLC_PHASE) <> 'RETIRE' or coalesce(a.ASSETS,0) > 0)
ORDER BY s.ACRONYM;