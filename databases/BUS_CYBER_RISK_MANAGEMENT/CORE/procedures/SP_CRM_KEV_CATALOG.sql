CREATE OR REPLACE PROCEDURE "SP_CRM_KEV_CATALOG"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Pull KEV (BOD) catalog'
EXECUTE AS OWNER
AS '

DECLARE
Appl varchar := ''SP_CRM_KEV_CATALOG'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
SNAPSHOT_ID number;
RECORD_COUNT NUMBER;
BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

--ExceptionMsg := ''Test Alert Monitoring''; 
--raise CRM_logic_exception;

CALL CORE.SP_CRM_PULL_KEV_CATALOG();
CALL CORE.SP_CRM_UPDATE_KEV_CATALOG(); -- Added 231103; Updates catalog with currenly available VULMASTER; It is run again after VULMASTER is updated; THIS MIGHT NOT BE NEEDED

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