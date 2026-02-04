CREATE OR REPLACE PROCEDURE "SP_CRM_PULL_CROWDSTRIKE_NEW"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Pull CROWDSTRIKE data into RAW_DATA table'
EXECUTE AS OWNER
AS '
--
-- 240820 as of creation of this SP, found that all Crowdstrike data had ASSET_ID_TATTOO populated.
-- Population examined was from 8/2/24 thru 8/20/24.
--
declare
Appl varchar := ''SP_CRM_PULL_CROWDSTRIKE_NEW'';
ExceptionMsg varchar;
Msg varchar;
StartOfProgram datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
Datacategory varchar := ''CROWDSTRIKE'';
SNAPSHOT_ID number;
RECORD_COUNT number;
PreviousPullDatetime TIMESTAMP_LTZ(9);
MIN_DATE TIMESTAMP_LTZ(9);
MAX_DATE TIMESTAMP_LTZ(9);

begin
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);
--
-- 240821 CR958; creation of this stored procedure
--

/*
CALL CORE.SP_CRM_GENERATE_SNAPSHOT_ID(:Datacategory);
SNAPSHOT_ID := CORE.FN_CRM_GET_SNAPSHOT_ID(:Datacategory);

PreviousPullDatetime := (select PARMDATE FROM CORE.CONFIG where PARMNAME = :Datacategory);
*/

SNAPSHOT_ID := (day(current_date()) || hour(current_timestamp()) || minute(current_timestamp()))::number;
Msg := ''Test SNAPSHOT_ID='' || :SNAPSHOT_ID;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

PreviousPullDatetime := ((current_date() - 1)::date || '' 00:01'')::timestamp;

Msg := ''Previous pull of '' || :Datacategory || ''='' || :PreviousPullDatetime;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

BEGIN TRANSACTION;

insert into CORE.RAW_DATA (
ASSET_ID_TAG
,ASSET_ID_TATTOO
,DATACENTER_ID
,DATA_ERROR_ARRAY
,DATA_WARNING_ARRAY
,DEVICETYPE
,FISMA_ID_TAG
,FQDN
,HOSTNAME
,INSERT_DATE
,IPV4
,IS_SYSTEM_ID_DEFAULTED_TO_DC
,MACADDRESS
,OS
,OS_BUILD_NUMBER
,LAST_SEEN
,REPORTDATE
,ROWDISPOSITION
,SYSTEM_ID
,SNAPSHOT_ID
,SOURCE_TOOL
)
SELECT
cs.ASSET_ID as ASSET_ID_TAG
,cs.ASSET_ID as ASSET_ID_TATTOO
,cs.DATA_CENTER as DATACENTER_ID
,ARRAY_CONSTRUCT() as DATA_ERROR_ARRAY
,ARRAY_CONSTRUCT() as DATA_WARNING_ARRAY
,cs.TYPE as DEVICE_TYPE
--,FILENAME
,cs.FISMA_TAG as FISMA_ID_TAG
,STRTOK_TO_ARRAY(cs.FQDN,'','') as FQDN
,STRTOK_TO_ARRAY(cs.HOSTNAME,'','') as HOSTNAME
,CURRENT_TIMESTAMP() as INSERT_DATE
,cs.IP_ADDRESSES as IPV4
,0 as IS_SYSTEM_ID_DEFAULTED_TO_DC
,cs.MAC_ADDRESSES as MACADDRESS
,cs.OS
,cs.OS_BUILD_NUMBER
-- ,SNOWPIPE_LOAD_TS
-- ,TAG always empty. Purpose unknown
,cs.TIMESTAMP as LAST_SEEN
,cs.S3_FILE_TS as REPORTDATE
,CORE.FN_CRM_GET_ROWDISPOSITION_VIABLE() as ROWDISPOSITION
,cs.FISMA_TAG as SYSTEM_ID
,:SNAPSHOT_ID as SNAPSHOT_ID
,:Datacategory as SOURCE_TOOL
FROM APP_CROWDSTRIKE.SHARED.SEC_VW_CROWDSTRIKE cs
JOIN (select r1.DATA_CENTER,r1.ASSET_ID,r1.TIMESTAMP
FROM (select rank()over(partition by DATA_CENTER,ASSET_ID order by TIMESTAMP desc) TheRank,DATA_CENTER,ASSET_ID,TIMESTAMP
    from APP_CROWDSTRIKE.SHARED.SEC_VW_CROWDSTRIKE
    WHERE S3_FILE_TS > :PreviousPullDatetime) r1 where r1.TheRank = 1) t on t.DATA_CENTER = cs.DATA_CENTER and t.ASSET_ID = cs.ASSET_ID and t.TIMESTAMP = cs.TIMESTAMP
WHERE cs.S3_FILE_TS > :PreviousPullDatetime
;

RECORD_COUNT := SQLROWCOUNT;

COMMIT;

IF (:RECORD_COUNT = 0) THEN
	BEGIN
	Msg := ''WARNING: There is no data for this snapshot'';
	CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    CALL CORE.SP_CRM_END_PROCEDURE (:Appl);
	RETURN :Msg;
	END;
ELSE
    BEGIN
    Msg := :Datacategory || '' inserted into RAW_DATA='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
END IF;

MIN_DATE := (select MIN(LAST_SEEN) FROM CORE.RAW_DATA WHERE SNAPSHOT_ID = :SNAPSHOT_ID);
MAX_DATE := (select MAX(LAST_SEEN) FROM CORE.RAW_DATA WHERE SNAPSHOT_ID = :SNAPSHOT_ID);

BEGIN TRANSACTION;

UPDATE CORE.SNAPSHOT_IDS
set MIN_DATE = :MIN_DATE
,MAX_DATE = :MAX_DATE
,RECORD_COUNT = coalesce(:RECORD_COUNT,0)
 where SNAPSHOT_ID = :SNAPSHOT_ID;

/***************** COMMENT WHILE TESTING
UPDATE CORE.CONFIG
set PARMDATE = :MAX_DATE
where PARMNAME = :Datacategory and :MAX_DATE IS NOT NULL;
***************************************************************/
Msg := ''WARNING: Update of CORE.CONFIG disabled while testing'';
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

COMMIT;



BEGIN TRANSACTION;
-- 
-- 240820 found Tenant ID to contain lowercase character therefore must use upper function to parse
--
UPDATE CORE.RAW_DATA upd
set ASSET_ID_TATTOO = p.ASSET_ID_TATTOO -- 240827 CR-TBD
,DATACENTER_ID = p.DATACENTER_ID -- 240827 CR-TBD
,TENANT_ID = p.TENANT_ID -- 240827 CR-TBD
FROM CORE.RAW_DATA r
join table(CORE.FN_CRM_PARSE_DRAAS_ASSET_ID_TATTOO(r.ASSET_ID_TAG)) p -- 240827 CR-TBD
where r.SNAPSHOT_ID = :SNAPSHOT_ID 
and CORE.FN_CRM_IS_VALID_DRAAS_ASSET_ID_TATTOO(r.ASSET_ID_TAG) = 1 -- 240827 CR-TBD
and r.ASSET_ID_TAG IS NOT NULL -- 240916 1459 CR-EBF
and upd.RAW_ID = r.RAW_ID;

RECORD_COUNT := SQLROWCOUNT;

Msg := ''Tenant tags assigned='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

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
END
';