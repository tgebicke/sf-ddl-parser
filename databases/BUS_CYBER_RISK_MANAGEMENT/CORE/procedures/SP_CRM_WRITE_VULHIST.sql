CREATE OR REPLACE PROCEDURE "SP_CRM_WRITE_VULHIST"("P_REPORT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Write VULMASTER records to VULHIST. Asset and vul must be active.'
EXECUTE AS OWNER
AS '

DECLARE
Appl varchar := ''SP_CRM_WRITE_VULHIST'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
RECORD_COUNT number := 0;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

----------------------------------------------------------------------
--            VULHIST
----------------------------------------------------------------------

BEGIN TRANSACTION;

INSERT INTO CORE.VULHIST
    (CVE -- 240625 CR916
	,CVSSV2BASESCORE
	,CVSSV3BASESCORE
    ,DATEMITIGATED -- 240625 CR916
    ,DW_ASSET_ID -- 240625 CR916
	,DW_VUL_ID
	,EXPLOITAVAILABLE
    ,EXTENDED_MITIGATIONSTATUS -- 240625 CR916
    ,FIRSTSEEN -- 240625 CR916
    ,IS_LEGACY -- 240625 CR916
	,FISMASEVERITY
	,LASTFOUND
	,MITIGATIONSTATUS
    ,NUMERIC_SEVERITY -- 240625 CR916
    ,REPOSITORY_ID -- 240625 CR916
    ,VUL_DATECREATED -- 240625 CR916
	,REPORT_ID
	)
select 
vm.CVE -- 240625 CR916
,vm.CVSSV2BASESCORE
,vm.CVSSV3BASESCORE
,vm.DATEMITIGATED -- 240625 CR916
,vm.DW_ASSET_ID -- 240625 CR916
,vm.DW_VUL_ID
,vm.exploitAvailable
,vm.EXTENDED_MITIGATIONSTATUS -- 240625 CR916
,vm.FIRSTSEEN -- 240625 CR916
,vm.IS_LEGACY -- 240625 CR916
,vm.FISMAseverity
,vm.lastfound
,vm.MitigationStatus
,vm.NUMERIC_SEVERITY -- 240625 CR916
,vm.REPOSITORY_ID -- 240625 CR916
,vm.INSERT_DATE as VUL_DATECREATED -- 240625 CR916
,:P_REPORT_ID
FROM CORE.VW_VULMASTER vm
WHERE (vm.datemitigated IS NULL or datediff(day,vm.datemitigated,current_date()) <= 365) -- 231018 1656 when mitigated for more than a year dont write to history
;

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