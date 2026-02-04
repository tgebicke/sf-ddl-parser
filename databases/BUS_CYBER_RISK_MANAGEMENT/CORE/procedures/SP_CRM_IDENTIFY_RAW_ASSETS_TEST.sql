CREATE OR REPLACE PROCEDURE "SP_CRM_IDENTIFY_RAW_ASSETS_TEST"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Identify distinct assets and assign temporary DW_ASSET_ID to RAW_HWAM or RAW_TENABLE_VUL'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_IDENTIFY_RAW_ASSETS_TEST'';
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

IF (:PARENT_DATACATEGORY = :HWAM) THEN
	BEGIN
    BEGIN TRANSACTION;
    --
    -- 240813 1957 CR-EBF
    -- 
    UPDATE CORE.RAW_HWAM upd
     set TEST_VARCHAR = ''DATACENTER_ID:'' || DATACENTER_ID || '';NORMALIZED_ASSET_ID_TATTOO:'' || NORMALIZED_ASSET_ID_TATTOO
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_VARCHAR IS NULL and NULLIF(DATACENTER_ID,'''') IS NOT NULL and NULLIF(NORMALIZED_ASSET_ID_TATTOO,'''') IS NOT NULL;

    RECORD_COUNT := SQLROWCOUNT;

    IF (:RECORD_COUNT > 0) THEN
        BEGIN
        Msg := ''TEST_VARCHAR based on NORMALIZED_ASSET_ID_TATTOO='' || :RECORD_COUNT;
        CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
        END;
    End If;
    COMMIT;

    BEGIN TRANSACTION;
    --
    -- 240828 Remove IPV4,IPV6
    -- 240823 Remove MACADDRESS,MOTHERBOARD,TENANT_ID
    --
    UPDATE CORE.RAW_HWAM upd
    set TEST_VARCHAR =
    (''DATACENTER_ID:'' || coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
    || '';SYSTEM_ID:'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
    || '';NORMALIZED_FQDN:'' || coalesce(NULLIF(NORMALIZED_FQDN,''''),''ITSNULL'')
    || '';NORMALIZED_HOSTNAME:'' || coalesce(NULLIF(ARRAY_TO_STRING(NORMALIZED_HOSTNAME,'',''),''''),''ITSNULL'')
    || '';NORMALIZED_NETBIOSNAME:'' || coalesce(NULLIF(NORMALIZED_NETBIOSNAME,''''),''ITSNULL'')
    )
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_VARCHAR IS NULL and NULLIF(NORMALIZED_ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

    RECORD_COUNT := SQLROWCOUNT;

    IF (:RECORD_COUNT > 0) THEN
        BEGIN
        Msg := ''TEST_VARCHAR not based on NORMALIZED_ASSET_ID_TATTOO(A)='' || :RECORD_COUNT;
        CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
        END;
    End If;
    COMMIT;
    
    BEGIN TRANSACTION;
    --
    -- 240823 Remove MACADDRESS,MOTHERBOARD,TENANT_ID
    --
    UPDATE CORE.RAW_HWAM upd
    set TEST_VARCHAR =
    (''DATACENTER_ID:'' || coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
    || '';SYSTEM_ID:'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
    || '';NORMALIZED_FQDN:'' || coalesce(NULLIF(NORMALIZED_FQDN,''''),''ITSNULL'')
    || '';NORMALIZED_HOSTNAME:'' || coalesce(NULLIF(ARRAY_TO_STRING(NORMALIZED_HOSTNAME,'',''),''''),''ITSNULL'')
    || '';NORMALIZED_NETBIOSNAME:'' || coalesce(NULLIF(NORMALIZED_NETBIOSNAME,''''),''ITSNULL'')
    || '';IPV4:'' || coalesce(NULLIF(ARRAY_TO_STRING(IPV4,'',''),''''),''ITSNULL'')
    || '';IPV6:'' || coalesce(NULLIF(ARRAY_TO_STRING(IPV6,'',''),''''),''ITSNULL'')
    )
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_VARCHAR IS NULL and NULLIF(NORMALIZED_ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

    RECORD_COUNT := SQLROWCOUNT;

    IF (:RECORD_COUNT > 0) THEN
        BEGIN
        Msg := ''TEST_VARCHAR not based on NORMALIZED_ASSET_ID_TATTOO(B)='' || :RECORD_COUNT;
        CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
        END;
    End If;
    COMMIT;
   END;
Else
    BEGIN -- TENABLE
    If (:IS_FROM_AWS_FEED = 0) THEN
        BEGIN
        BEGIN TRANSACTION;
        --
        -- 240830 Remove IP
        -- 240823 Remove MACADDRESS,TENABLEUUID
        --
        UPDATE CORE.RAW_TENABLE_VUL upd
        set TEST_VARCHAR =
        (''DATACENTER_ID:'' || coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
        || '';SYSTEM_ID:'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
        || '';NORMALIZED_FQDN:'' || coalesce(NULLIF(NORMALIZED_FQDN,''''),''ITSNULL'')
        || '';NORMALIZED_HOSTNAME:'' || coalesce(NULLIF(ARRAY_TO_STRING(NORMALIZED_HOSTNAME,'',''),''''),''ITSNULL'')
        || '';NORMALIZED_NETBIOSNAME:'' || coalesce(NULLIF(NORMALIZED_NETBIOSNAME,''''),''ITSNULL'')
        || '';REPOSITORY_ID:'' || coalesce(NULLIF(REPOSITORY_ID,''''),''ITSNULL'')
        )
        WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_VARCHAR IS NULL and NULLIF(NORMALIZED_ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

        RECORD_COUNT := SQLROWCOUNT;

        IF (:RECORD_COUNT > 0) THEN
            BEGIN
            Msg := ''TEST_VARCHAR not based on NORMALIZED_ASSET_ID_TATTOO(A)='' || :RECORD_COUNT;
            CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
            END;
        End If;
        COMMIT;

        BEGIN TRANSACTION;
        --
        -- 240823 Remove MACADDRESS,TENABLEUUID
        --
        UPDATE CORE.RAW_TENABLE_VUL upd
        set TEST_VARCHAR =
        (''DATACENTER_ID:'' || coalesce(NULLIF(DATACENTER_ID,''''),''ITSNULL'')
        || '';SYSTEM_ID:'' || coalesce(NULLIF(SYSTEM_ID,''''),''ITSNULL'') -- Not available when data first written to table so probably not needed
        || '';NORMALIZED_FQDN:'' || coalesce(NULLIF(NORMALIZED_FQDN,''''),''ITSNULL'')
        || '';NORMALIZED_HOSTNAME:'' || coalesce(NULLIF(ARRAY_TO_STRING(NORMALIZED_HOSTNAME,'',''),''''),''ITSNULL'')
        || '';IP:'' || coalesce(NULLIF(IP,''''),''ITSNULL'')
        || '';NORMALIZED_NETBIOSNAME:'' || coalesce(NULLIF(NORMALIZED_NETBIOSNAME,''''),''ITSNULL'')
        || '';REPOSITORY_ID:'' || coalesce(NULLIF(REPOSITORY_ID,''''),''ITSNULL'')
        )
        WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_VARCHAR IS NULL and NULLIF(NORMALIZED_ASSET_ID_TATTOO,'''') IS NULL; -- 240813 1957 CR-EBF

        RECORD_COUNT := SQLROWCOUNT;

        IF (:RECORD_COUNT > 0) THEN
            BEGIN
            Msg := ''TEST_VARCHAR not based on NORMALIZED_ASSET_ID_TATTOO(B)='' || :RECORD_COUNT;
            CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
            END;
        End If;
        COMMIT;
        END;
    End If; -- IS_FROM_AWS_FEED
 
    BEGIN TRANSACTION;
    --
    -- 240917 CR-EBF enhance by testing for AWS
    -- 240813 1957 CR-EBF added code for DATACENTER_ID/NORMALIZED_ASSET_ID_TATTOO assignment
     -- 
    UPDATE CORE.RAW_TENABLE_VUL upd
    set TEST_VARCHAR = ''DATACENTER_ID:'' || DATACENTER_ID || '';NORMALIZED_ASSET_ID_TATTOO:'' || NORMALIZED_ASSET_ID_TATTOO
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_VARCHAR IS NULL and NULLIF(DATACENTER_ID,'''') IS NOT NULL and NULLIF(NORMALIZED_ASSET_ID_TATTOO,'''') IS NOT NULL;

    RECORD_COUNT := SQLROWCOUNT;

    IF (:RECORD_COUNT > 0) THEN
        BEGIN
        Msg := ''TEST_VARCHAR based on NORMALIZED_ASSET_ID_TATTOO='' || :RECORD_COUNT;
        CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
        END;
    End If;
    COMMIT;
    END; -- TENABLE
END IF;


------------------------------------------------------------------------
--
-- ASSIGN TEST_NUMBER BASED ON TEST_VARCHAR
--
------------------------------------------------------------------------

IF (:PARENT_DATACATEGORY = :HWAM) THEN
	BEGIN
    BEGIN TRANSACTION;
    UPDATE CORE.RAW_HWAM upd
    set TEST_NUMBER = seq.SEQ_TEMP_DW_ASSET_ID
    FROM (select d.TEST_VARCHAR,SEQ_TEMP_DW_ASSET_ID.NEXTVAL as SEQ_TEMP_DW_ASSET_ID
        FROM (select DISTINCT TEST_VARCHAR
            FROM CORE.RAW_HWAM where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_NUMBER IS NULL) d) seq  
    WHERE upd.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.TEST_VARCHAR = seq.TEST_VARCHAR and upd.TEST_NUMBER IS NULL;

    RECORD_COUNT := SQLROWCOUNT;
    COMMIT;
    END;
Else
    BEGIN
    BEGIN TRANSACTION;
    UPDATE CORE.RAW_TENABLE_VUL upd
    set TEST_NUMBER = seq.SEQ_TEMP_DW_ASSET_ID
    FROM (select d.TEST_VARCHAR,SEQ_TEMP_DW_ASSET_ID.NEXTVAL as SEQ_TEMP_DW_ASSET_ID
        FROM (select DISTINCT TEST_VARCHAR
            FROM CORE.RAW_TENABLE_VUL where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_NUMBER IS NULL) d) seq  
    WHERE upd.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.TEST_VARCHAR = seq.TEST_VARCHAR and upd.TEST_NUMBER IS NULL;

    RECORD_COUNT := SQLROWCOUNT;
    COMMIT;
    END;
END IF;

Msg := ''TEST_NUMBER assigned='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

IF (:PARENT_DATACATEGORY = :HWAM) THEN
    BEGIN
    select count(1) into :RECORD_COUNT FROM CORE.RAW_HWAM where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_NUMBER IS NULL;
    END;
Else
    BEGIN
    select count(1) into :RECORD_COUNT FROM CORE.RAW_TENABLE_VUL where SNAPSHOT_ID = :P_SNAPSHOT_ID and TEST_NUMBER IS NULL;
    END;
END IF;

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