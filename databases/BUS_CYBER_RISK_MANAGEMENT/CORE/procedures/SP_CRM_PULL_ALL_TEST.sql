CREATE OR REPLACE PROCEDURE "SP_CRM_PULL_ALL_TEST"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Pull all data into RAW_DATA table'
EXECUTE AS OWNER
AS '
--
-- 
--
declare
Appl varchar := ''SP_CRM_PULL_ALL_TEST'';
ExceptionMsg varchar;
Msg varchar;
StartOfProgram datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
PreviousPullDatetime TIMESTAMP_LTZ(9);
SNAPSHOT_ID number;
RECORD_COUNT number;
MIN_DATE TIMESTAMP_LTZ(9);
MAX_DATE TIMESTAMP_LTZ(9);

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

TRUNCATE TABLE CORE.RAW_DATA;

CALL CORE.SP_CRM_PULL_AWS_HWAM_NEW(); -- LAST_CONFIRMED_TIME avail
select system$wait(60);
CALL CORE.SP_CRM_PULL_AXONIUS_NEW();
select system$wait(60);
CALL CORE.SP_CRM_PULL_CCIC_VUL_NEW(''CCIC VUL'');
select system$wait(60);
CALL CORE.SP_CRM_PULL_CCIC_VUL_NEW(''CCIC VUL MITIGATED'');
select system$wait(60);
CALL CORE.SP_CRM_PULL_CROWDSTRIKE_NEW();
select system$wait(60);
CALL CORE.SP_CRM_PULL_FORESCOUT_NEW();
select system$wait(60);
CALL CORE.SP_CRM_PULL_IUSG_VUL_NEW(''AWS VUL'');
select system$wait(60);
CALL CORE.SP_CRM_PULL_IUSG_VUL_NEW(''AWS VUL MITIGATED'');
select system$wait(60);
CALL CORE.SP_CRM_PULL_MAG_VUL_NEW(''MAG VUL'');
select system$wait(60);
CALL CORE.SP_CRM_PULL_MAG_VUL_NEW(''MAG VUL MITIGATED'');


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