CREATE OR REPLACE PROCEDURE "SP_CRM_HEALTH_CHECKER"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Check CYBER_RISK_MANAGEMENT DB for various inconsistencies'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_HEALTH_CHECKER'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
False boolean := 0;
True boolean := 1;
--CURRENT_REPORT_ID NUMBER := (SELECT MAX(REPORT_ID) FROM CORE.REPORT_IDS);
RECORD_COUNT NUMBER;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

--select count(1) into :RECORD_COUNT
--   FROM (select AXONIUS_INTERNAL_AXONIUS_ID 
--    from asset where AXONIUS_INTERNAL_AXONIUS_ID is not null
--    group by AXONIUS_INTERNAL_AXONIUS_ID having count(1) > 1);
--
--Msg := ''Duplicate AXONIUS_INTERNAL_AXONIUS_ID='' || :RECORD_COUNT;
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

--
-- Check for AssetInterface records with no associated Asset record.  THIS SHOULD NOT BE
--
select count(1) into :RECORD_COUNT
from CORE.ASSETINTERFACE_FQDN ai
left outer join CORE.ASSET a on a.dw_asset_id = ai.dw_asset_id
where a.dw_asset_id is null;

If (:RECORD_COUNT > 0) THEN -- 231130
    BEGIN
    Msg := ''ASSETINTERFACE_FQDN without ASSET='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT
from CORE.ASSETINTERFACE_HOSTNAME ai
left outer join CORE.ASSET a on a.dw_asset_id = ai.dw_asset_id
where a.dw_asset_id is null;

If (:RECORD_COUNT > 0) THEN -- 231130
    BEGIN
    Msg := ''ASSETINTERFACE_HOSTNAME without ASSET='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT
from CORE.ASSETINTERFACE_IPV4 ai
left outer join CORE.ASSET a on a.dw_asset_id = ai.dw_asset_id
where a.dw_asset_id is null;

If (:RECORD_COUNT > 0) THEN -- 231130
    BEGIN
    Msg := ''ASSETINTERFACE_IPV4 without ASSET='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT
from CORE.ASSETINTERFACE_IPV6 ai
left outer join CORE.ASSET a on a.dw_asset_id = ai.dw_asset_id
where a.dw_asset_id is null;

If (:RECORD_COUNT > 0) THEN -- 231130
    BEGIN
    Msg := ''ASSETINTERFACE_IPV6 without ASSET='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT
from CORE.ASSETINTERFACE_MACADDRESS ai
left outer join CORE.ASSET a on a.dw_asset_id = ai.dw_asset_id
where a.dw_asset_id is null;

If (:RECORD_COUNT > 0) THEN -- 231130
    BEGIN
    Msg := ''ASSETINTERFACE_MACADDRESS without ASSET='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT
from CORE.ASSETINTERFACE_NETBIOSNAME ai
left outer join CORE.ASSET a on a.dw_asset_id = ai.dw_asset_id
where a.dw_asset_id is null;

If (:RECORD_COUNT > 0) THEN -- 231130
    BEGIN
    Msg := ''ASSETINTERFACE_NETBIOSNAME without ASSET='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT
from CORE.VULMASTER vm
left outer join CORE.ASSET a on a.dw_asset_id = vm.dw_asset_id
where a.dw_asset_id is null;

If (:RECORD_COUNT > 0) THEN -- 231130
    BEGIN
    Msg := ''VULMASTER without ASSET='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT from INFORMATION_SCHEMA.FUNCTIONS WHERE FUNCTION_SCHEMA = ''CORE'' AND COMMENT IS NULL; -- 231213
If (:RECORD_COUNT > 0) THEN 
    BEGIN
    Msg := ''CORE.Functions needing comment='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT from INFORMATION_SCHEMA.PROCEDURES WHERE PROCEDURE_SCHEMA = ''CORE'' AND COMMENT IS NULL; -- 231213
If (:RECORD_COUNT > 0) THEN 
    BEGIN
    Msg := ''CORE.Procedures needing comment='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

-- 240110 The TABLES view seems to also contain VIEWS
select count(1) into :RECORD_COUNT from INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ''CORE'' AND COMMENT IS NULL; -- 231213
If (:RECORD_COUNT > 0) THEN 
    BEGIN
    Msg := ''CORE.Tables needing comment='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

--240113
select count(1) into :RECORD_COUNT
    from CORE.VW_ASSETS a
    left outer join CORE.SYSTEMS s on s.system_id = a.system_id
    where s.system_id is null;

If (:RECORD_COUNT > 0) THEN 
    BEGIN
    Msg := ''WARNING: Asset table has invalid SYSTEM_ID='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

--240113
select count(1) into :RECORD_COUNT
    from CORE.VW_ASSETS a
    left outer join CORE.SYSTEMS dc on dc.system_id = a.datacenter_id
    where dc.system_id is null;

If (:RECORD_COUNT > 0) THEN 
    BEGIN
    Msg := ''WARNING: Asset table has invalid DATACENTER_ID='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

select count(1) into :RECORD_COUNT from CORE.VULPLUGINS_MASTER where mitigationstatus <> ''fixed'';

If (:RECORD_COUNT > 0) THEN 
    BEGIN
    Msg := ''VULPLUGINS_MASTER still open='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

-- 240611
SELECT COUNT(1) into :RECORD_COUNT FROM (select DW_ASSET_ID,NORMALIZED_FQDN from ASSETINTERFACE_FQDN group by DW_ASSET_ID,NORMALIZED_FQDN having count(1) > 1);

-- If (:RECORD_COUNT > 0) THEN 
--     BEGIN
    Msg := ''ASSETINTERFACE_FQDN duplicates='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
--     END;
-- End if;

-- 240611
SELECT COUNT(1) into :RECORD_COUNT FROM (select DW_ASSET_ID,NORMALIZED_NETBIOSNAME from ASSETINTERFACE_NETBIOSNAME group by DW_ASSET_ID,NORMALIZED_NETBIOSNAME having count(1) > 1);

-- If (:RECORD_COUNT > 0) THEN 
--     BEGIN
    Msg := ''ASSETINTERFACE_NETBIOSNAME duplicates='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
--     END;
-- End if;

-- 240611
SELECT COUNT(1) into :RECORD_COUNT FROM (select DW_ASSET_ID,NORMALIZED_HOSTNAME from ASSETINTERFACE_HOSTNAME group by DW_ASSET_ID,NORMALIZED_HOSTNAME having count(1) > 1);

-- If (:RECORD_COUNT > 0) THEN 
--     BEGIN
    Msg := ''ASSETINTERFACE_HOSTNAME duplicates='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
--     END;
-- End if;


-- 240110 select count(1) into :RECORD_COUNT from INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = ''CORE'' AND COMMENT IS NULL; -- 231213
-- 240110 If (:RECORD_COUNT > 0) THEN 
-- 240110     BEGIN
-- 240110     Msg := ''CORE.Views needing comment='' || :RECORD_COUNT;
-- 240110     CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
-- 240110     END;
-- 240110 End if;

--231222
-- 240113 select count(1) into :RECORD_COUNT from (select distinct instanceid from APP_TENABLE.SHARED.SEC_VW_IUSG_CUMULATIVE_VULNS where s3_file_create::date = current_date()); -- 240102 added current_date()
-- 240113 If (:RECORD_COUNT > 0) THEN 
-- 240113     BEGIN
-- 240113     Msg := ''SEC_VW_IUSG_CUMULATIVE_VULNS Assets='' || :RECORD_COUNT;
-- 240113     CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
-- 240113     END;
-- 240113 End if;

--231222
-- 240113 select count(1) into :RECORD_COUNT from (select distinct instanceid from APP_TENABLE.SHARED.SEC_VW_VULN_AWS where report_date::date = current_date()); -- 240102 added current_date()
-- 240113 If (:RECORD_COUNT > 0) THEN 
-- 240113     BEGIN
-- 240113     Msg := ''SEC_VW_VULN_AWS Assets='' || :RECORD_COUNT;
-- 240113     CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
-- 240113     END;
-- 240113 End if;



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