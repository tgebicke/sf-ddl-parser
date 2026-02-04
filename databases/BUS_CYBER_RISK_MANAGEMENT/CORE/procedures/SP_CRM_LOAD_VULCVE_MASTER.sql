CREATE OR REPLACE PROCEDURE "SP_CRM_LOAD_VULCVE_MASTER"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Load VULPLUGINS_MASTER data into VULMASTER which contains distinct cves per asset'
EXECUTE AS OWNER
AS '
declare
Appl varchar := ''SP_CRM_LOAD_VULCVE_MASTER'';
ExceptionMsg varchar;
Msg varchar;
StartOfProgram datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
RowDispositionError varchar := ''Error''; 
RECORD_COUNT number;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

BEGIN TRANSACTION;

------------------------
-- BEGINNING OF MERGE --
------------------------
MERGE INTO CORE.VULMASTER target USING
 (SELECT Maxplugin.CVE
,Maxplugin.Max_CVSSV2BASESCORE as CVSSV2BASESCORE
,Maxplugin.Max_CVSSV3BASESCORE as CVSSV3BASESCORE
,datediff(day,Maxplugin.Min_firstseen,Maxplugin.Max_lastfound) as DAYSSINCEDISCOVERY
,Maxplugin.dw_asset_id
,Maxplugin.Max_DW_PLUGIN_VUL_ID as DW_PLUGIN_VUL_ID
,case Maxplugin.Max_exploitavailable
    when 1 then ''Yes''
    Else ''No''
End as EXPLOITAVAILABLE
,Maxplugin.Min_firstseen as FIRSTSEEN
,case Maxplugin.Max_numeric_severity
    when 4 then ''Critical''
    when 3 then ''High''
    when 2 then ''Medium''
    when 1 then ''Low''
    Else ''Unknown''
End as FISMASEVERITY
,vulp.IS_FROM_AWS_FEED
,IFF(DATE_PART(YEAR, Maxplugin.Min_firstseen) < 2021, 1, 0) as IS_LEGACY
,Maxplugin.Max_lastfound as LASTFOUND
,case Maxplugin.Max_has_been_mitigated
    when 1 then ''reopened''
    Else ''open''
End as MITIGATIONSTATUS
,Maxplugin.Max_numeric_severity as NUMERIC_SEVERITY
,vulp.REPOSITORY_NAME
,vulp.REPOSITORY_ID -- 230720
from (select dw_asset_id,f.value::string as cve,min(firstseen) as Min_firstseen, Max(lastfound) as Max_lastfound,max(numeric_severity) as Max_numeric_severity
    ,max(IFF(upper(r.exploitavailable) = ''YES'',1,0)::number) as Max_exploitavailable
    ,max(r.has_been_mitigated::number) as Max_has_been_mitigated
    ,max(r.CVSSV2BASESCORE) as Max_CVSSV2BASESCORE
    ,max(r.CVSSV3BASESCORE) as Max_CVSSV3BASESCORE
    ,max(r.DW_PLUGIN_VUL_ID) as Max_DW_PLUGIN_VUL_ID
    
    FROM CORE.VULPLUGINS_MASTER r
    join table(flatten(cve,outer=>true)) as f
    WHERE r.SNAPSHOT_ID = :P_SNAPSHOT_ID
    group by dw_asset_id,f.value::string) Maxplugin
    join CORE.VULPLUGINS_MASTER vulp on vulp.DW_PLUGIN_VUL_ID = Maxplugin.Max_DW_PLUGIN_VUL_ID
) src

ON (src.DW_ASSET_ID = target.DW_ASSET_ID and src.CVE = target.CVE)

WHEN MATCHED THEN UPDATE SET 
-- Never change DW_ASSET_ID, CVE, FIRSTSEEN after initial row creation (Insert)
target.CVSSV2BASESCORE          = src.CVSSV2BASESCORE
,target.CVSSV3BASESCORE         = src.CVSSV3BASESCORE
,target.DATEDELETED             = null
,target.DATEMITIGATED           = null -- If it was once mitigated it is now open/reopened again so erase prior datemitigated
,target.DATEMODIFIED            = CURRENT_TIMESTAMP() -- DATEMODIFIED. Setting this is critical to SP_CRM_UPDATE_VULCVE_MASTER
,target.DATEREOPENED            = IFF(src.MITIGATIONSTATUS = ''reopened'', src.LASTFOUND, NULL)
,target.DAYSSINCEDISCOVERY      = src.DAYSSINCEDISCOVERY
,target.DELETIONREASON          = null
,target.DW_PLUGIN_VUL_ID_MODIFY = src.DW_PLUGIN_VUL_ID
,target.EXPLOITAVAILABLE        = src.EXPLOITAVAILABLE
,target.FISMASEVERITY           = src.FISMASEVERITY
,target.IS_LEGACY               = src.IS_LEGACY
,target.LASTFOUND               = src.LASTFOUND
,target.MITIGATIONSTATUS        = src.MITIGATIONSTATUS
,target.NUMERIC_SEVERITY        = src.NUMERIC_SEVERITY
,target.REPOSITORY_NAME         = src.REPOSITORY_NAME
,target.REPOSITORY_ID           = src.REPOSITORY_ID

WHEN NOT MATCHED THEN INSERT(
	 CVE
	,CVSSV2BASESCORE
	,CVSSV3BASESCORE
	,DATEDELETED
	,DATEMITIGATED
	,DATEMODIFIED
	,DATEREOPENED
	,DAYSSINCEDISCOVERY
	,DELETIONREASON
	,DW_ASSET_ID
    ,DW_PLUGIN_VUL_ID_CREATE
    ,DW_PLUGIN_VUL_ID_MODIFY
	,EXPLOITAVAILABLE
	,FIRSTSEEN
	,FISMASEVERITY
	,INSERT_DATE
    ,IS_FROM_AWS_FEED
	,IS_LEGACY
    ,IS_PREV_DELETED
	,LASTFOUND
	,MITIGATIONSTATUS
	,NUMERIC_SEVERITY
	,ORIG_FISMASEVERITY
	,ORIG_MITIGATIONSTATUS
	,PREV_FISMASEVERITY
	,PREV_MITIGATIONSTATUS
    ,REPOSITORY_NAME
    ,REPOSITORY_ID
)
VALUES (
	 src.CVE
	,src.CVSSV2BASESCORE
	,src.CVSSV3BASESCORE
	,null -- DATEDELETED
	,null -- DATEMITIGATED
	,CURRENT_TIMESTAMP() -- DATEMODIFIED. Setting this is critical to SP_CRM_UPDATE_VULCVE_MASTER
	,IFF(src.MITIGATIONSTATUS = ''reopened'', src.LASTFOUND, NULL) -- DATEREOPENED
	,src.DAYSSINCEDISCOVERY
	,null -- DELETIONREASON
	,src.DW_ASSET_ID
    ,src.DW_PLUGIN_VUL_ID -- DW_PLUGIN_VUL_ID_CREATE
    ,src.DW_PLUGIN_VUL_ID -- DW_PLUGIN_VUL_ID_MODIFY
	,src.EXPLOITAVAILABLE
	,src.FIRSTSEEN
	,src.FISMASEVERITY
	,CURRENT_TIMESTAMP() -- INSERT_DATE
    ,src.IS_FROM_AWS_FEED
	,src.IS_LEGACY
    ,0 -- IS_PREV_DELETED
	,src.LASTFOUND
	,src.MITIGATIONSTATUS
	,src.NUMERIC_SEVERITY
	,src.FISMASEVERITY -- ORIG_FISMASEVERITY
	,src.MITIGATIONSTATUS -- ORIG_MITIGATIONSTATUS
	,src.FISMASEVERITY -- PREV_FISMASEVERITY
	,src.MITIGATIONSTATUS -- PREV_MITIGATIONSTATUS
    ,src.REPOSITORY_NAME
    ,src.REPOSITORY_ID
);

COMMIT;


BEGIN TRANSACTION;
--
-- Update LASTSEEN_VUL based on any vulnerability record received (including Informational) as long as record is not in error.
-- APPLICABILITYCODE does not need to equal ApplicabilityCode_Actionable
--
update CORE.ASSET upd
set LASTSEEN_VUL =  v.Max_LAST_SEEN
,DATEMODIFIED = CURRENT_TIMESTAMP()
FROM CORE.ASSET a
JOIN (select dw_asset_id,max(last_seen) as Max_LAST_SEEN
    from CORE.RAW_TENABLE_VUL where snapshot_id = :P_SNAPSHOT_ID and ROWDISPOSITION <> :RowDispositionError and DW_ASSET_ID IS NOT NULL and DW_ASSET_ID > 0
    group by dw_asset_id) v on v.dw_asset_id = a.dw_asset_id
where a.DW_ASSET_ID = upd.DW_ASSET_ID;

COMMIT;

CALL CORE.SP_CRM_END_PROCEDURE (:Appl);
return ''Success'';

EXCEPTION
  when statement_error then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''Statement_Error'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
  when CRM_logic_exception then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''CRM_logic_exception'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
  when other then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''Other error'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
END;
';