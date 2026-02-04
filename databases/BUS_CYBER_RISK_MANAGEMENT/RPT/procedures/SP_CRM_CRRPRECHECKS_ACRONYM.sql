CREATE OR REPLACE PROCEDURE "SP_CRM_CRRPRECHECKS_ACRONYM"()
RETURNS TABLE ()
LANGUAGE SQL
COMMENT='CRM stored procedure for CRRPreChecks'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_CRRPreChecks'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
res RESULTSET;


BEGIN
CALL CORE.SP_CRM_START_PROCEDURE(:Appl);

-- Checking acronyms
CREATE TEMPORARY TABLE temp_Validate (
	COMPONENT_ACRONYM varchar,
	GROUP_ACRONYM varchar,
	ACRONYM varchar,
    TLC_PHASE varchar,
    FIRST_PUBLISHED_DATE Date
	);
INSERT INTO temp_Validate select Component_Acronym, Group_Acronym, Acronym, TLC_Phase, first_published_date from CORE.SYSTEMS s
where Acronym not in (select Systems from rpt.CRR_Component_Params) and TLC_Phase <> ''Retire'' and Component_Acronym <> ''Not specified'';

delete from temp_Validate where Group_Acronym not in (
Select distinct c.groups from temp_Validate temp
join rpt.CRR_Component_Params C on C.Component = temp.Component_Acronym
) and Component_Acronym not in (
Select distinct C.Component from temp_Validate temp
join rpt.CRR_Component_Params C on C.Component = temp.Component_Acronym
);

res := (select * from temp_Validate);
drop table temp_Validate;
  
CALL CORE.SP_CRM_END_PROCEDURE(:Appl);

RETURN TABLE(res);

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