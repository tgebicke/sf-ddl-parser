CREATE OR REPLACE PROCEDURE "SP_CRM_PULL_AXONIUS_NEW"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Pull AXONIUS data into CRM'
EXECUTE AS OWNER
AS '
--
-- CRM once ingested Axonius data encompassing multiple systems (prior to 240226) but this newest version is
-- specific to HIGALS data only
--
declare
Appl varchar := ''SP_CRM_PULL_AXONIUS_NEW'';
ExceptionMsg varchar;
Msg varchar;
StartOfProgram datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
Datacategory varchar := ''AXONIUS'';
SNAPSHOT_ID number;
RECORD_COUNT number;
PreviousPullDatetime TIMESTAMP_LTZ(9);
MIN_DATE TIMESTAMP_LTZ(9);
MAX_DATE TIMESTAMP_LTZ(9);

begin
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

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
ASSET_ID_TATTOO
,DATACENTER_ID
,DATA_ERROR_ARRAY
,DATA_WARNING_ARRAY
,DEVICETYPE
,FQDN
,HOSTNAME
,INSERT_DATE
,IPV4
,IPV6
,LAST_SEEN
,MACADDRESS
,OS
,OS_VERSION
,REPORTDATE
,ROWDISPOSITION
,SYSTEM_ID
,SNAPSHOT_ID
,SOURCE_TOOL
)
SELECT
ax.AXON_ID as ASSET_ID_TATTOO
,ax.DATACENTER_ID
,ARRAY_CONSTRUCT() as DATA_ERROR_ARRAY
,ARRAY_CONSTRUCT() as DATA_WARNING_ARRAY
,ax.DEVICE_TYPE
,STRTOK_TO_ARRAY(ax.FQDN,'','') as FQDN
,STRTOK_TO_ARRAY(ax.HOST_NAME,'','') as HOSTNAME
,CURRENT_TIMESTAMP() as INSERT_DATE
,ax.IPV4
,ax.IPV6
,ax.LAST_CONFIRMED_TIME as LAST_SEEN
,ax.MAC_ADDRESS as MACADDRESS
,ax.OS
,ax.OS_VERSION
,ax.REPORT_DATE as REPORTDATE
,CORE.FN_CRM_GET_ROWDISPOSITION_VIABLE() as ROWDISPOSITION
,ax.FISMA_ID as SYSTEM_ID
,:SNAPSHOT_ID as SNAPSHOT_ID
,:Datacategory as SOURCE_TOOL
FROM APP_AXONIUS.SHARED.SEC_VW_HWAM_HIGLAS ax -- 241008 CR996 APP_HIGLAS DB RENAMED TO APP_AXONIUS
JOIN (select r1.DATACENTER_ID,r1.AXON_ID,r1.REPORT_DATE,r1.LAST_CONFIRMED_TIME
FROM (select rank()over(partition by DATACENTER_ID,AXON_ID order by REPORT_DATE desc, LAST_CONFIRMED_TIME desc) TheRank,DATACENTER_ID,AXON_ID, REPORT_DATE,LAST_CONFIRMED_TIME
    from APP_AXONIUS.SHARED.SEC_VW_HWAM_HIGLAS
    WHERE REPORT_DATE > :PreviousPullDatetime) r1 where r1.TheRank = 1) t on t.DATACENTER_ID = ax.DATACENTER_ID and t.AXON_ID = ax.AXON_ID and t.REPORT_DATE = ax.REPORT_DATE
    and t.LAST_CONFIRMED_TIME = ax.LAST_CONFIRMED_TIME
WHERE ax.REPORT_DATE > :PreviousPullDatetime;

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