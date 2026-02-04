CREATE OR REPLACE PROCEDURE "SP_CRM_NORMALIZE_ASSET_IDENTIFIERS"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Normalize asset identifiable columns in Raw data table. These are used in the asset matching process'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_NORMALIZE_ASSET_IDENTIFIERS'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
PARENT_DATACATEGORY varchar;
DATACATEGORY varchar;
HWAM varchar := ''HWAM'';
VUL varchar := ''VUL'';
RECORD_COUNT number;

BEGIN
select DATACATEGORY,PARENT_DATACATEGORY into :DATACATEGORY,:PARENT_DATACATEGORY FROM CORE.SNAPSHOT_IDS where SNAPSHOT_ID = :P_SNAPSHOT_ID;
Appl := :Appl || ''('' || DATACATEGORY || '')''; -- This helps to clarify which snapshot we are processing
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

BEGIN TRANSACTION;
--
-- 240606 CR903 first introduced normalization into SP_CRM_LOAD_ASSET_V2
--
-- NORMALIZE certain fields to be used in asset matching.
-- ASSET_ID_TATTOO found differences in case depending on the sensor
-- FQDN is almost always a single value so an array is not needed. I found 5 cases over 90 days where there was more than one value but they were bogus
-- HOSTNAME needs to be an array. Had to flatten HOSTNAME in order to do split_part then re-create array.
-- NETBIOSNAME is almost always a single value so an array is not needed. I found 1 case over 90 days where there was more than one value but it was bogus
-- MACADDRESS needs to be an array
--
-- Also note: When testing this sql in a separate worksheet remove one of the back-slashes between the double-dollars
--
IF (:PARENT_DATACATEGORY = :HWAM) THEN
    BEGIN
    UPDATE RAW_HWAM upd
    set NORMALIZED_ASSET_ID_TATTOO = UPPER(th.ASSET_ID_TATTOO)
    ,NORMALIZED_FQDN = UPPER(NULLIF(GET(th.FQDN,0)::varchar,''''))
    ,NORMALIZED_HOSTNAME = n.NORMALIZED_HOSTNAME
    ,NORMALIZED_NETBIOSNAME = UPPER(coalesce(NULLIF(split_part(GET(th.NETBIOSNAME,0)::varchar,$$\\$$,2),''''),GET(th.NETBIOSNAME,0)::varchar)) -- Use double-dollars to avoid back-slash escape
    ,NORMALIZED_MACADDRESS = STRTOK_TO_ARRAY(UPPER(REPLACE(REPLACE(ARRAY_TO_STRING(th.MACADDRESS,''$''),'':'',''''),''-'','''')),'','') 
    ,NORMALIZED_MOTHERBOARD = UPPER(th.MOTHERBOARD)
    FROM (SELECT r.RAW_HWAM_ID,ARRAY_AGG(NULLIF(REPLACE(UPPER(coalesce(split_part(f.value::string,''.'',1),split_part(GET(r.fqdn,0),''.'',1))),''*'',''''),'''')) as NORMALIZED_HOSTNAME
        FROM RAW_HWAM r
        join table(flatten(HOSTNAME,outer=>true)) as f
        where r.SNAPSHOT_ID = :P_SNAPSHOT_ID
        GROUP BY r.RAW_HWAM_ID) n
    JOIN RAW_HWAM th on th.RAW_HWAM_ID = n.RAW_HWAM_ID
    WHERE upd.RAW_HWAM_ID = th.RAW_HWAM_ID;
    END;
ELSE
    BEGIN
    UPDATE RAW_TENABLE_VUL upd
    set NORMALIZED_ASSET_ID_TATTOO = UPPER(th.ASSET_ID_TATTOO)
    ,NORMALIZED_FQDN = UPPER(th.DNSNAME)
    ,NORMALIZED_HOSTNAME = STRTOK_TO_ARRAY(UPPER(th.HOSTNAME),'','')
    ,NORMALIZED_NETBIOSNAME = UPPER(th.NETBIOSNAME)
    ,NORMALIZED_MACADDRESS = STRTOK_TO_ARRAY(UPPER(REPLACE(REPLACE(th.MACADDRESS,'':'',''''),''-'','''')),'','')
    ,NORMALIZED_MOTHERBOARD = NULL -- Motherboard is not in RAW_TENABLE_VUL
    FROM RAW_TENABLE_VUL th
    WHERE th.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.RAW_TENABLE_VUL_ID = th.RAW_TENABLE_VUL_ID;
    END;
END IF;
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