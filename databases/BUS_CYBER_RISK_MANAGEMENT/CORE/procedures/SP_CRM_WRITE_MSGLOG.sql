CREATE OR REPLACE PROCEDURE "SP_CRM_WRITE_MSGLOG"("P_APPL" VARCHAR(16777216), "P_MSG" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Write message to CYBER_RISK_MANAGEMENT Msglog'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_WRITE_MSGLOG'';
ExceptionMsg varchar;
StartOfProgram datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
BEGIN

BEGIN TRANSACTION;
insert into CORE.MSGLOG (APPL,MSG) VALUES(:P_APPL,:P_MSG);
COMMIT;

--
-- 241030
-- There should never be a null msg so if one is found something is fundamentally wrong.
--
If (NULLIF(:P_MSG,'''') IS NULL) THEN
    BEGIN
    ExceptionMsg := ''ERROR: FOUND NULL MSG''; 
    raise CRM_logic_exception;
    END;
END IF;

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