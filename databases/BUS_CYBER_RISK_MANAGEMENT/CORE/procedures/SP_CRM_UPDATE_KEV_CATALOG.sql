CREATE OR REPLACE PROCEDURE "SP_CRM_UPDATE_KEV_CATALOG"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Update KEV_CATALOG with exploitAvailable and FISMAseverity based on actual open vulnerabilities'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_UPDATE_KEV_CATALOG'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
TheRowCount NUMBER := 0;
BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

BEGIN TRANSACTION;

UPDATE CORE.KEV_CATALOG upd
set exploitAvailable = r.exploitAvailable
,FISMAseverity = r.FISMAseverity
,LASTFOUND = r.lastfound
FROM CORE.KEV_CATALOG kev
JOIN (select m.cve,t.exploitAvailable,t.FISMAseverity,T.lastfound
	FROM (SELECT CVE,MAX(lastfound) as MaxLastFound
		FROM CORE.VW_VULMASTER
		where IS_KEV = 1 and MitigationStatus <> ''fixed''
		GROUP by CVE) m
	JOIN (SELECT distinct CVE,lastfound,exploitAvailable,FISMAseverity
		FROM CORE.VW_VULMASTER
		where IS_KEV = 1 and MitigationStatus <> ''fixed'') t on t.CVE = m.CVE and t.lastfound = m.MaxLastFound) r on r.CVE = kev.CVE
where kev.ID = upd.ID;

COMMIT;

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