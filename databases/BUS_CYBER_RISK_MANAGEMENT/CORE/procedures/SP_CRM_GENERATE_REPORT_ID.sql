CREATE OR REPLACE PROCEDURE "SP_CRM_GENERATE_REPORT_ID"()
RETURNS NUMBER(38,0)
LANGUAGE SQL
COMMENT='Generate next sequential REPORT_ID'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_GENERATE_REPORT_ID'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
NEW_REPORT_ID NUMBER;

BEGIN

-- 240416 CR873 The IS_VIABLE flag is initially created as FALSE. When morning processes complete successfully it sets IS_VIABLE = TRUE

BEGIN TRANSACTION;
insert into CORE.REPORT_IDS (IS_ENDOFMONTH,REPORT_DATE,IS_VIABLE) VALUES(0,CURRENT_TIMESTAMP(),0); -- 240416 CR873
COMMIT;

SELECT MAX(REPORT_ID) INTO :NEW_REPORT_ID FROM CORE.REPORT_IDS;

Msg := ''Created REPORT_ID:'' || :NEW_REPORT_ID;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

RETURN :NEW_REPORT_ID;

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