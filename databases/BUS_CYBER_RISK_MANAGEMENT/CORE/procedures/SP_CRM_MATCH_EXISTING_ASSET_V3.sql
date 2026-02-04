CREATE OR REPLACE PROCEDURE "SP_CRM_MATCH_EXISTING_ASSET_V3"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Attempt to match TEMP_HWAM data against ASSET/ASSETINTERFACE tables'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_MATCH_EXISTING_ASSET_V3'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
False boolean := 0;
True boolean := 1;
DATACATEGORY varchar;
RECORD_COUNT NUMBER;
REMAINING_RECORDS_TO_MATCH NUMBER;
MATCHMETHOD varchar;
LOOP_COUNTER NUMBER;
IS_FROM_AWS_FEED boolean;
IS_SEARCH_SYSTEM_ID boolean;
LOOP_TEXT VARCHAR;
IS_ENABLE_STEP_MSG boolean := 1;
MAG_VUL varchar := ''MAG VUL''; -- 241025 CR1012
MAG_VUL_MITIGATED varchar := ''MAG VUL MITIGATED''; -- 241025 CR1012

BEGIN
select DATACATEGORY,IS_FROM_AWS_FEED into :DATACATEGORY,:IS_FROM_AWS_FEED FROM CORE.SNAPSHOT_IDS where SNAPSHOT_ID = :P_SNAPSHOT_ID;
Appl := :Appl || ''('' || :DATACATEGORY || '')''; -- This helps to clarify which datastream we are processing
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

/********************
BEGIN TRANSACTION;
UPDATE TEMP_HWAM
set DW_ASSET_ID = NULL
,MATCHMETHOD = NULL
,DATEMODIFIED = NULL
,MATCHORDER = NULL
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID;
COMMIT;

Msg := ''WARNING: Initialized TEMP_HWAM while testing'';
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); 
************************************************/


select count(1) INTO :RECORD_COUNT FROM TEMP_HWAM WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID;
Msg := ''TEMP_HWAM to match='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;


BEGIN TRANSACTION; -- 241025 CR1015
BEGIN
-- Renju found that the FISMA ID (SYSTEM_ID) for AdMed-GSS had both upper and lower case
-- values of the SYSTEM_ID when the SYSTEMS (master) table has it as lower case. 
-- Research shows upper case values being provided from FORESCOUT and Tenable and is mostly likely due
-- to an incorrect tag placed on the asset. SDW is using the upper function to validate SYSTEM_ID (which passes) but 
-- incorrectly writes the upshifted SYSTEM_ID to the ASSET table.
-- This correction should be made in the Prep or Metadata procedures but is being done here to expedite the correction, 
--
UPDATE TEMP_HWAM upd
set SYSTEM_ID = ns.SYSTEM_ID -- unaltered case
FROM TEMP_HWAM th
LEFT OUTER JOIN SYSTEMS s on s.SYSTEM_ID = th.SYSTEM_ID
JOIN SYSTEMS ns on upper(ns.SYSTEM_ID) = upper(th.SYSTEM_ID)
WHERE th.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.TEMP_HWAM_ID = th.TEMP_HWAM_ID and s.SYSTEM_ID IS NULL;
END;
COMMIT;



---------------------------------------------------------------------------------------------
--
-- LOOP TWO TIMES
--
-- 240828 We no longer distinguish between active/inactive assets. (Is_Applicable = 1/0)
--
-- 1) Search for existing assets where SYSTEM_ID matches
-- 2) Search for existing assets where SYSTEM_ID is ignored
--
---------------------------------------------------------------------------------------------


FOR LOOP_COUNTER IN 1 TO 2 DO

If (:LOOP_COUNTER = 1) THEN
    BEGIN
    IS_SEARCH_SYSTEM_ID := 1;
    LOOP_TEXT := ''SYSTEM_ID,'';
    END;
Else
    BEGIN
    IS_SEARCH_SYSTEM_ID := 0;
    LOOP_TEXT := ''(Ignore SYSTEM_ID)'';
    END;
End if;

If (:IS_FROM_AWS_FEED = 1 or (:DATACATEGORY in (:MAG_VUL,:MAG_VUL_MITIGATED))) THEN
    BEGIN
    BEGIN TRANSACTION;
    If (:IS_FROM_AWS_FEED = 1) THEN
        BEGIN
        MATCHMETHOD := ''(AWS)'' || ''DATACENTER_ID,ASSET_ID_TATTOO'';
        END;
    ELSEIF (:DATACATEGORY in (:MAG_VUL,:MAG_VUL_MITIGATED)) THEN
        BEGIN
        MATCHMETHOD := ''(MAG)'' || ''DATACENTER_ID,ASSET_ID_TATTOO'';
        END;
    End if;
 

    --
    -- DATACENTER_ID/ASSET_ID_TATTOO matching is a special (favorable) case especially in the AWS environment 
    -- where an InstanceID (ASSET_ID_TATTOO) is always available.
    --
    -- The Asset (MDR) table should only have one distinct row with DATACENTER_ID/ASSET_ID_TATTOO
    -- whether or not IS_APPLICABLE flag is true.
    --
    UPDATE TEMP_HWAM upd
    set DW_ASSET_ID = src.DW_ASSET_ID
    ,MATCHMETHOD = :MATCHMETHOD
    ,DATEMODIFIED = current_timestamp()
    ,MATCHORDER = (:LOOP_COUNTER * 100) + 5
    FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        JOIN ASSET a on a.DATACENTER_ID = th.DATACENTER_ID and a.ASSET_ID_TATTOO = th.ASSET_ID_TATTOO
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.ASSET_ID_TATTOO,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
    WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
    RECORD_COUNT := SQLROWCOUNT;
    COMMIT;
   

    Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
    If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;

    --
    -- Exit loop. Any remaining TEMP_HWAM will be created as new assets at a later step
    --
    BREAK; -- Exit the loop.
    END;
END IF;

select COUNT(1) INTO :REMAINING_RECORDS_TO_MATCH FROM TEMP_HWAM WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_ASSET_ID IS NULL;
If (:REMAINING_RECORDS_TO_MATCH = 0) THEN
    BEGIN
    --
    -- All TEMP_HWAM rows have been assigned a DW_ASSET_ID
    --
    Msg := ''All TEMP_HWAM rows have been assigned a DW_ASSET_ID'';
    If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;
    BREAK; -- Exit the loop. No more matching needed. This will probably be rare.
    END;
END IF;

Msg := ''LOOP_COUNTER='' || :LOOP_COUNTER::varchar || '', LOOP_TEXT='' || :LOOP_TEXT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;

BEGIN TRANSACTION;
MATCHMETHOD := :LOOP_TEXT || ''DATACENTER_ID,FQDN,HOSTNAME,NETBIOSNAME,MOTHERBOARD,IPV4'';

UPDATE TEMP_HWAM upd
set DW_ASSET_ID = src.DW_ASSET_ID
,MATCHMETHOD = :MATCHMETHOD
,DATEMODIFIED = current_timestamp()
,MATCHORDER = (:LOOP_COUNTER * 100) + 20
FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        join table(flatten(NORMALIZED_HOSTNAME,outer=>true)) as fh
        join table(flatten(IPV4,outer=>true)) as fi4
        JOIN ASSETINTERFACE_FQDN fqdn on fqdn.NORMALIZED_FQDN = th.NORMALIZED_FQDN
        JOIN ASSET a on a.DW_ASSET_ID = fqdn.DW_ASSET_ID and a.DATACENTER_ID = th.DATACENTER_ID 
            and (:IS_SEARCH_SYSTEM_ID = 0 or (:IS_SEARCH_SYSTEM_ID = 1 and a.SYSTEM_ID = th.SYSTEM_ID))
            and a.MOTHERBOARD = th.MOTHERBOARD
        JOIN ASSETINTERFACE_HOSTNAME hn on hn.DW_ASSET_ID = a.DW_ASSET_ID and hn.NORMALIZED_HOSTNAME = fh.value::string
        JOIN ASSETINTERFACE_NETBIOSNAME nbn on nbn.DW_ASSET_ID = a.DW_ASSET_ID and nbn.NORMALIZED_NETBIOSNAME = th.NORMALIZED_NETBIOSNAME
        JOIN ASSETINTERFACE_IPV4 ip4 on ip4.DW_ASSET_ID = a.DW_ASSET_ID and ip4.IPV4 = fi4.value::string
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.NORMALIZED_FQDN,'''') IS NOT NULL 
        and NULLIF(fh.value::string,'''') IS NOT NULL
        and NULLIF(th.NORMALIZED_NETBIOSNAME,'''') IS NOT NULL
        and NULLIF(th.MOTHERBOARD,'''') IS NOT NULL
        and NULLIF(fi4.value::string,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;

BEGIN TRANSACTION;
MATCHMETHOD := :LOOP_TEXT || ''DATACENTER_ID,FQDN,HOSTNAME,NETBIOSNAME,IPV4'';

UPDATE TEMP_HWAM upd
set DW_ASSET_ID = src.DW_ASSET_ID
,MATCHMETHOD = :MATCHMETHOD
,DATEMODIFIED = current_timestamp()
,MATCHORDER = (:LOOP_COUNTER * 100) + 23
FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        join table(flatten(NORMALIZED_HOSTNAME,outer=>true)) as fh
        join table(flatten(IPV4,outer=>true)) as fi4
        JOIN ASSETINTERFACE_FQDN fqdn on fqdn.NORMALIZED_FQDN = th.NORMALIZED_FQDN
        JOIN ASSET a on a.DW_ASSET_ID = fqdn.DW_ASSET_ID and a.DATACENTER_ID = th.DATACENTER_ID 
            and (:IS_SEARCH_SYSTEM_ID = 0 or (:IS_SEARCH_SYSTEM_ID = 1 and a.SYSTEM_ID = th.SYSTEM_ID))
        JOIN ASSETINTERFACE_HOSTNAME hn on hn.DW_ASSET_ID = a.DW_ASSET_ID and hn.NORMALIZED_HOSTNAME = fh.value::string
        JOIN ASSETINTERFACE_NETBIOSNAME nbn on nbn.DW_ASSET_ID = a.DW_ASSET_ID and nbn.NORMALIZED_NETBIOSNAME = th.NORMALIZED_NETBIOSNAME
        JOIN ASSETINTERFACE_IPV4 ip4 on ip4.DW_ASSET_ID = a.DW_ASSET_ID and ip4.IPV4 = fi4.value::string
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.NORMALIZED_FQDN,'''') IS NOT NULL 
        and NULLIF(fh.value::string,'''') IS NOT NULL
        and NULLIF(th.NORMALIZED_NETBIOSNAME,'''') IS NOT NULL
        and NULLIF(fi4.value::string,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;


BEGIN TRANSACTION; -- 280828 CR-TBD New search
MATCHMETHOD := :LOOP_TEXT || ''DATACENTER_ID,FQDN,HOSTNAME,NETBIOSNAME'';

UPDATE TEMP_HWAM upd
set DW_ASSET_ID = src.DW_ASSET_ID
,MATCHMETHOD = :MATCHMETHOD
,DATEMODIFIED = current_timestamp()
,MATCHORDER = (:LOOP_COUNTER * 100) + 24
FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        join table(flatten(NORMALIZED_HOSTNAME,outer=>true)) as fh
        JOIN ASSETINTERFACE_FQDN fqdn on fqdn.NORMALIZED_FQDN = th.NORMALIZED_FQDN
        JOIN ASSET a on a.DW_ASSET_ID = fqdn.DW_ASSET_ID and a.DATACENTER_ID = th.DATACENTER_ID 
            and (:IS_SEARCH_SYSTEM_ID = 0 or (:IS_SEARCH_SYSTEM_ID = 1 and a.SYSTEM_ID = th.SYSTEM_ID))
        JOIN ASSETINTERFACE_HOSTNAME hn on hn.DW_ASSET_ID = a.DW_ASSET_ID and hn.NORMALIZED_HOSTNAME = fh.value::string
        JOIN ASSETINTERFACE_NETBIOSNAME nbn on nbn.DW_ASSET_ID = a.DW_ASSET_ID and nbn.NORMALIZED_NETBIOSNAME = th.NORMALIZED_NETBIOSNAME
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.NORMALIZED_FQDN,'''') IS NOT NULL 
        and NULLIF(fh.value::string,'''') IS NOT NULL
        and NULLIF(th.NORMALIZED_NETBIOSNAME,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;


BEGIN TRANSACTION;
MATCHMETHOD := :LOOP_TEXT || ''DATACENTER_ID,FQDN,HOSTNAME,IPV4'';

UPDATE TEMP_HWAM upd
set DW_ASSET_ID = src.DW_ASSET_ID
,MATCHMETHOD = :MATCHMETHOD
,DATEMODIFIED = current_timestamp()
,MATCHORDER = (:LOOP_COUNTER * 100) + 30
FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        join table(flatten(NORMALIZED_HOSTNAME,outer=>true)) as fh
        join table(flatten(IPV4,outer=>true)) as fi4
        JOIN ASSETINTERFACE_FQDN fqdn on fqdn.NORMALIZED_FQDN = th.NORMALIZED_FQDN
        JOIN ASSET a on a.DW_ASSET_ID = fqdn.DW_ASSET_ID and a.DATACENTER_ID = th.DATACENTER_ID 
            and (:IS_SEARCH_SYSTEM_ID = 0 or (:IS_SEARCH_SYSTEM_ID = 1 and a.SYSTEM_ID = th.SYSTEM_ID))
        JOIN ASSETINTERFACE_HOSTNAME hn on hn.DW_ASSET_ID = a.DW_ASSET_ID and hn.NORMALIZED_HOSTNAME = fh.value::string
        JOIN ASSETINTERFACE_IPV4 ip4 on ip4.DW_ASSET_ID = a.DW_ASSET_ID and ip4.IPV4 = fi4.value::string
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.NORMALIZED_FQDN,'''') IS NOT NULL 
        and NULLIF(fh.value::string,'''') IS NOT NULL
        and NULLIF(th.NORMALIZED_NETBIOSNAME,'''') IS NULL
        and NULLIF(fi4.value::string,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;


BEGIN TRANSACTION;
MATCHMETHOD := :LOOP_TEXT || ''DATACENTER_ID,HOSTNAME,IPV4'';

UPDATE TEMP_HWAM upd
set DW_ASSET_ID = src.DW_ASSET_ID
,MATCHMETHOD = :MATCHMETHOD
,DATEMODIFIED = current_timestamp()
,MATCHORDER = (:LOOP_COUNTER * 100) + 40
FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        join table(flatten(NORMALIZED_HOSTNAME,outer=>true)) as fh
        join table(flatten(IPV4,outer=>true)) as fi4
        JOIN ASSETINTERFACE_HOSTNAME hn on hn.NORMALIZED_HOSTNAME = fh.value::string
        JOIN ASSET a on a.DW_ASSET_ID = hn.DW_ASSET_ID and a.DATACENTER_ID = th.DATACENTER_ID 
            and (:IS_SEARCH_SYSTEM_ID = 0 or (:IS_SEARCH_SYSTEM_ID = 1 and a.SYSTEM_ID = th.SYSTEM_ID))
        JOIN ASSETINTERFACE_IPV4 ip4 on ip4.DW_ASSET_ID = a.DW_ASSET_ID and ip4.IPV4 = fi4.value::string
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(fh.value::string,'''') IS NOT NULL
        and NULLIF(fi4.value::string,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;

BEGIN TRANSACTION;
MATCHMETHOD := :LOOP_TEXT || ''DATACENTER_ID,NETBIOSNAME,IPV4'';

UPDATE TEMP_HWAM upd
set DW_ASSET_ID = src.DW_ASSET_ID
,MATCHMETHOD = :MATCHMETHOD
,DATEMODIFIED = current_timestamp()
,MATCHORDER = (:LOOP_COUNTER * 100) + 50
FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        join table(flatten(IPV4,outer=>true)) as fi4
        JOIN ASSETINTERFACE_NETBIOSNAME nbn on nbn.NORMALIZED_NETBIOSNAME = th.NORMALIZED_NETBIOSNAME
        JOIN ASSET a on a.DW_ASSET_ID = nbn.DW_ASSET_ID and a.DATACENTER_ID = th.DATACENTER_ID 
            and (:IS_SEARCH_SYSTEM_ID = 0 or (:IS_SEARCH_SYSTEM_ID = 1 and a.SYSTEM_ID = th.SYSTEM_ID))
        JOIN ASSETINTERFACE_IPV4 ip4 on ip4.DW_ASSET_ID = a.DW_ASSET_ID and ip4.IPV4 = fi4.value::string
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.NORMALIZED_NETBIOSNAME,'''') IS NOT NULL
        and NULLIF(fi4.value::string,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;

BEGIN TRANSACTION;
MATCHMETHOD := :LOOP_TEXT || ''DATACENTER_ID,FQDN,HOSTNAME'';

UPDATE TEMP_HWAM upd
set DW_ASSET_ID = src.DW_ASSET_ID
,MATCHMETHOD = :MATCHMETHOD
,DATEMODIFIED = current_timestamp()
,MATCHORDER = (:LOOP_COUNTER * 100) + 60
FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        join table(flatten(NORMALIZED_HOSTNAME,outer=>true)) as fh
        JOIN ASSETINTERFACE_FQDN fqdn on fqdn.NORMALIZED_FQDN = th.NORMALIZED_FQDN
        JOIN ASSET a on a.DW_ASSET_ID = fqdn.DW_ASSET_ID and a.DATACENTER_ID = th.DATACENTER_ID 
            and (:IS_SEARCH_SYSTEM_ID = 0 or (:IS_SEARCH_SYSTEM_ID = 1 and a.SYSTEM_ID = th.SYSTEM_ID))
        JOIN ASSETINTERFACE_HOSTNAME hn on hn.DW_ASSET_ID = a.DW_ASSET_ID and hn.NORMALIZED_HOSTNAME = fh.value::string
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.NORMALIZED_FQDN,'''') IS NOT NULL
        and NULLIF(fh.value::string,'''') IS NOT NULL
        and NULLIF(th.NORMALIZED_NETBIOSNAME,'''') IS NULL
        GROUP BY th.TEMP_HWAM_ID) src
WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
RECORD_COUNT := SQLROWCOUNT;
COMMIT;

Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;

END FOR OUTERLOOP; -- END OF LOOP


If (:IS_FROM_AWS_FEED = 0) THEN
    BEGIN
    BEGIN TRANSACTION;
    MATCHMETHOD := ''DATACENTER_ID,ASSET_ID_TATTOO'';
    --
    -- 240823 DATACENTER_ID/ASSET_ID_TATTOO matching is a special (favorable) case.
    -- The Asset (MDR) table should only have one distinct row with DATACENTER_ID/ASSET_ID_TATTOO
    -- whether or not IS_APPLICABLE flag is true
    --
    UPDATE TEMP_HWAM upd
    set DW_ASSET_ID = src.DW_ASSET_ID
    ,MATCHMETHOD = :MATCHMETHOD
    ,DATEMODIFIED = current_timestamp()
    ,MATCHORDER = 300 -- We are outside the loop
    FROM (select MIN(a.DW_ASSET_ID) as DW_ASSET_ID,th.TEMP_HWAM_ID
        FROM TEMP_HWAM th
        JOIN ASSET a on a.DATACENTER_ID = th.DATACENTER_ID and a.ASSET_ID_TATTOO = th.ASSET_ID_TATTOO
        WHERE th.DW_ASSET_ID IS NULL
        and th.SNAPSHOT_ID = :P_SNAPSHOT_ID
        and NULLIF(th.ASSET_ID_TATTOO,'''') IS NOT NULL
        GROUP BY th.TEMP_HWAM_ID) src
    WHERE upd.DW_ASSET_ID IS NULL and upd.TEMP_HWAM_ID = src.TEMP_HWAM_ID;
    RECORD_COUNT := SQLROWCOUNT;
    COMMIT;

    Msg := ''MATCHMETHOD:'' || :MATCHMETHOD || ''='' || :RECORD_COUNT;
    If (:IS_ENABLE_STEP_MSG = 1) THEN CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); End if;
    END;
END IF;

select count(1) into :RECORD_COUNT FROM TEMP_HWAM where SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_ASSET_ID IS NULL;
Msg := ''Unmatched records (To be created as new assets)='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

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