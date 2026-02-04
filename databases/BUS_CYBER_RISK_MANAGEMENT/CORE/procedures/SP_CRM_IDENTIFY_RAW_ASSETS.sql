CREATE OR REPLACE PROCEDURE "SP_CRM_IDENTIFY_RAW_ASSETS"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Identify distinct assets and assign temporary DW_ASSET_ID to RAW_HWAM or RAW_TENABLE_VUL'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_IDENTIFY_RAW_ASSETS'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
HWAM varchar := ''HWAM'';
RECORD_COUNT NUMBER;
DATACATEGORY varchar;
PARENT_DATACATEGORY varchar;

BEGIN
select DATACATEGORY,PARENT_DATACATEGORY into :DATACATEGORY,:PARENT_DATACATEGORY FROM CORE.SNAPSHOT_IDS where SNAPSHOT_ID = :P_SNAPSHOT_ID;
Appl := :Appl || ''('' || DATACATEGORY || '')''; -- This helps to clarify which snapshot we are processing
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

IF (:PARENT_DATACATEGORY = :HWAM) THEN
	BEGIN
    BEGIN TRANSACTION;
    --
    -- 240813 1957 CR-EBF
    -- 
    UPDATE CORE.RAW_HWAM upd
    set TEMP_ASSET_KEY = DATACENTER_ID || '';'' || ASSET_ID_TATTOO
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_ASSET_KEY IS NULL and NULLIF(DATACENTER_ID,'''') IS NOT NULL and NULLIF(ASSET_ID_TATTOO,'''') IS NOT NULL;

    RECORD_COUNT := SQLROWCOUNT;
    Msg := ''TEMP_ASSET_KEY based on ASSET_ID_TATTOO='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    COMMIT;

    BEGIN TRANSACTION;
    --
    -- 240828 Remove IPV4,IPV6
    -- 240823 Remove MACADDRESS,MOTHERBOARD,TENANT_ID
    --
    UPDATE CORE.RAW_HWAM upd
    set TEMP_ASSET_KEY =
    (coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(FQDN,'',''),''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(HOSTNAME,'',''),''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(NETBIOSNAME,'',''),''''),''ITSNULL'')
    )
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_ASSET_KEY IS NULL and NULLIF(ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

    RECORD_COUNT := SQLROWCOUNT;
    Msg := ''TEMP_ASSET_KEY not based on ASSET_ID_TATTOO='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    COMMIT;

    BEGIN TRANSACTION;
    --
    -- 240823 Remove MACADDRESS,MOTHERBOARD,TENANT_ID
    --
    UPDATE CORE.RAW_HWAM upd
    set TEMP_ASSET_KEY =
    (coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(FQDN,'',''),''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(HOSTNAME,'',''),''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(NETBIOSNAME,'',''),''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(IPV4,'',''),''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(ARRAY_TO_STRING(IPV6,'',''),''''),''ITSNULL'')
    )
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_ASSET_KEY IS NULL and NULLIF(ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

    RECORD_COUNT := SQLROWCOUNT;
    Msg := ''TEMP_ASSET_KEY not based on ASSET_ID_TATTOO='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    COMMIT;
   END;
Else
    BEGIN -- TENABLE
    BEGIN TRANSACTION;
    --
    -- 240813 1957 CR-EBF
    -- 
    UPDATE CORE.RAW_TENABLE_VUL upd
    set TEMP_ASSET_KEY = DATACENTER_ID || '';'' || ASSET_ID_TATTOO
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_ASSET_KEY IS NULL and NULLIF(DATACENTER_ID,'''') IS NOT NULL and NULLIF(ASSET_ID_TATTOO,'''') IS NOT NULL;

    RECORD_COUNT := SQLROWCOUNT;
    Msg := ''TEMP_ASSET_KEY based on ASSET_ID_TATTOO='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    COMMIT;

    BEGIN TRANSACTION;
    --
    -- 240830 Remove IP
    -- 240823 Remove MACADDRESS,TENABLEUUID
    --
    UPDATE CORE.RAW_TENABLE_VUL upd
    set TEMP_ASSET_KEY =
    (coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
    || '';'' || coalesce(NULLIF(DNSNAME,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(HOSTNAME,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(NETBIOSNAME,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(REPOSITORY_ID,''''),''ITSNULL'')
    )
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_ASSET_KEY IS NULL and NULLIF(ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

    RECORD_COUNT := SQLROWCOUNT;
    Msg := ''TEMP_ASSET_KEY not based on ASSET_ID_TATTOO='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    COMMIT;

   BEGIN TRANSACTION;
    --
    -- 240823 Remove MACADDRESS,TENABLEUUID
    --
    UPDATE CORE.RAW_TENABLE_VUL upd
    set TEMP_ASSET_KEY =
    (coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
    || '';'' || coalesce(NULLIF(DNSNAME,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(HOSTNAME,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(IP,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(NETBIOSNAME,''''),''ITSNULL'')
    || '';'' || coalesce(NULLIF(REPOSITORY_ID,''''),''ITSNULL'')
    )
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_ASSET_KEY IS NULL and NULLIF(ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

    RECORD_COUNT := SQLROWCOUNT;
    Msg := ''TEMP_ASSET_KEY not based on ASSET_ID_TATTOO='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    COMMIT;
    END;
END IF;


IF (:PARENT_DATACATEGORY = :HWAM) THEN
	BEGIN
    BEGIN TRANSACTION;
    UPDATE CORE.RAW_HWAM upd
    set TEMP_DW_ASSET_ID = seq.SEQ_TEMP_DW_ASSET_ID
    FROM (select d.TEMP_ASSET_KEY,SEQ_TEMP_DW_ASSET_ID.NEXTVAL as SEQ_TEMP_DW_ASSET_ID
        FROM (select DISTINCT TEMP_ASSET_KEY
            FROM CORE.RAW_HWAM where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_DW_ASSET_ID IS NULL) d) seq  
    WHERE upd.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.TEMP_ASSET_KEY = seq.TEMP_ASSET_KEY and upd.TEMP_DW_ASSET_ID IS NULL;

    RECORD_COUNT := SQLROWCOUNT;
    COMMIT;
    END;
Else
    BEGIN
    BEGIN TRANSACTION;
    UPDATE CORE.RAW_TENABLE_VUL upd
    set TEMP_DW_ASSET_ID = seq.SEQ_TEMP_DW_ASSET_ID
    FROM (select d.TEMP_ASSET_KEY,SEQ_TEMP_DW_ASSET_ID.NEXTVAL as SEQ_TEMP_DW_ASSET_ID
        FROM (select DISTINCT TEMP_ASSET_KEY
            FROM CORE.RAW_TENABLE_VUL where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_DW_ASSET_ID IS NULL) d) seq  
    WHERE upd.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.TEMP_ASSET_KEY = seq.TEMP_ASSET_KEY and upd.TEMP_DW_ASSET_ID IS NULL;

    RECORD_COUNT := SQLROWCOUNT;
    COMMIT;
    END;
END IF;

Msg := ''TEMP_DW_ASSET_ID assigned='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

IF (:PARENT_DATACATEGORY = :HWAM) THEN
    BEGIN
    select count(1) into :RECORD_COUNT FROM CORE.RAW_HWAM where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_DW_ASSET_ID IS NULL;
    END;
Else
    BEGIN
    select count(1) into :RECORD_COUNT FROM CORE.RAW_TENABLE_VUL where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEMP_DW_ASSET_ID IS NULL;
    END;
END IF;

If (:RECORD_COUNT > 0) THEN
    BEGIN
    Msg := ''WARNING: TEMP_DW_ASSET_ID Unassigned='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); 
    END;
Else
    BEGIN
    Msg := ''All records have been assigned a TEMP_DW_ASSET_ID'';
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