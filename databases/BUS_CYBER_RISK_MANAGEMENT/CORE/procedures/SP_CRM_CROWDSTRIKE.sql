CREATE OR REPLACE PROCEDURE "SP_CRM_CROWDSTRIKE"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Pull CROWDSTRIKE HWAM, update/insert Master Device Record(MDR)'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_CROWDSTRIKE'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
SNAPSHOT_ID number;
RECORD_COUNT NUMBER;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);
--
-- 240821 CR958; creation of this stored procedure
--
CALL CORE.SP_CRM_PULL_CROWDSTRIKE();
SNAPSHOT_ID := CORE.FN_CRM_GET_SNAPSHOT_ID(''CROWDSTRIKE'');
CALL CORE.SP_CRM_IDENTIFY_RAW_ASSETS(:SNAPSHOT_ID);
CALL CORE.SP_CRM_PREP_RAW_HWAM_V2(:SNAPSHOT_ID);
CALL CORE.SP_CRM_LOAD_ASSET_V2(:SNAPSHOT_ID);

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