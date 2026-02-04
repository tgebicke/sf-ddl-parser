CREATE OR REPLACE PROCEDURE "SP_CRM_END_PROCEDURE"("P_APPL" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Write End of Application message to CYBER_RISK_MANAGEMENT Msglog'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_END_PROCEDURE'';
ExceptionMsg varchar := ''Default'';
StartOfProcedure datetime;
ELAPSED_MILLISECONDS NUMBER;
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
BEGIN

ELAPSED_MILLISECONDS := 0; -- 240429 timestampdiff(millisecond,StartOfProcedure,CURRENT_TIMESTAMP());

BEGIN TRANSACTION;
insert into CORE.MSGLOG (APPL,ELAPSED_MILLISECONDS,MSG) VALUES(:P_APPL,:ELAPSED_MILLISECONDS,''Ending Application'');
COMMIT;

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