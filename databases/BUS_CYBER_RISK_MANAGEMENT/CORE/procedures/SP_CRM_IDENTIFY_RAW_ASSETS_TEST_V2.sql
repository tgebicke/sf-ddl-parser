CREATE OR REPLACE PROCEDURE "SP_CRM_IDENTIFY_RAW_ASSETS_TEST_V2"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Identify distinct assets and assign temporary DW_ASSET_ID to RAW_HWAM or RAW_TENABLE_VUL'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_IDENTIFY_RAW_ASSETS_TEST_V2'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
HWAM varchar := ''HWAM'';
IS_FROM_AWS_FEED BOOLEAN; -- 240917 CR-EBF
RECORD_COUNT NUMBER;
DATACATEGORY varchar;
PARENT_DATACATEGORY varchar;

BEGIN
--
-- 240917 CR-EBF added IS_FROM_AWS_FEED
--
select DATACATEGORY,PARENT_DATACATEGORY,IS_FROM_AWS_FEED into :DATACATEGORY,:PARENT_DATACATEGORY,:IS_FROM_AWS_FEED FROM CORE.SNAPSHOT_IDS where SNAPSHOT_ID = :P_SNAPSHOT_ID;
Appl := :Appl || ''('' || DATACATEGORY || '')''; -- This helps to clarify which snapshot we are processing
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

IF (:DATACATEGORY NOT in (''CCIC VUL'',''CCIC VUL MITIGATED'')) THEN
    BEGIN
    Msg := ''Only testing CCIC VUL and CCIC VUL MITIGATED'';
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    return :Msg;
    END;
END IF;

BEGIN TRANSACTION;
UPDATE CORE.RAW_TENABLE_VUL
set TEST_VARCHAR = NULL
,TEST_NUMBER = NULL
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID;
COMMIT;


UPDATE CORE.RAW_TENABLE_VUL
set TEST_VARCHAR =
        (''REPOSITORY_ID:'' || coalesce(NULLIF(REPOSITORY_ID,''''),''ITSNULL'')
        || '';REPOSITORY_DESCRIPTION:'' || coalesce(NULLIF(REPOSITORY_DESCRIPTION,''''),''ITSNULL'')
        || '';IP:'' || coalesce(NULLIF(IP,''''),''ITSNULL'')
        || '';DNSNAME:'' || coalesce(NULLIF(DNSNAME,''''),''ITSNULL'')
        )
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_VARCHAR IS NULL;
        

 ------------------------------------------------------------------------
--
-- ASSIGN TEST_NUMBER BASED ON TEST_VARCHAR
--
------------------------------------------------------------------------

BEGIN TRANSACTION;
UPDATE CORE.RAW_TENABLE_VUL upd
set TEST_NUMBER = seq.SEQ_TEMP_DW_ASSET_ID
    FROM (select d.TEST_VARCHAR,SEQ_TEMP_DW_ASSET_ID.NEXTVAL as SEQ_TEMP_DW_ASSET_ID
        FROM (select DISTINCT TEST_VARCHAR
            FROM CORE.RAW_TENABLE_VUL where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_NUMBER IS NULL) d) seq  
    WHERE upd.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.TEST_VARCHAR = seq.TEST_VARCHAR and upd.TEST_NUMBER IS NULL;

    RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''TEST_NUMBER assigned='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

select count(1) into :RECORD_COUNT FROM CORE.RAW_TENABLE_VUL where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_NUMBER IS NULL;

If (:RECORD_COUNT > 0) THEN
    BEGIN
    Msg := ''WARNING: TEST_NUMBER Unassigned='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); 
    END;
Else
    BEGIN
    Msg := ''All records have been assigned a TEST_NUMBER'';
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); 
    END;
END IF;

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