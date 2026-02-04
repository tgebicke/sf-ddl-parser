CREATE OR REPLACE PROCEDURE "SP_CRM_UPDATE_VULPLUGINS_MASTER"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Update VULPLUGINS_MASTER with a) fixed mitigation staus, delete rows not scanned by cutoff (days), delete rows where asset has been deleted'
EXECUTE AS OWNER
AS '
declare
Appl varchar := ''SP_CRM_UPDATE_VULPLUGINS_MASTER'';
ExceptionMsg varchar;
Msg varchar;
StartOfProgram datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
AWS_VUL_MITIGATED varchar := ''AWS VUL MITIGATED'';
CCIC_VUL_MITIGATED varchar := ''CCIC VUL MITIGATED'';
MAG_VUL_MITIGATED varchar := ''MAG VUL MITIGATED''; -- 241023 CR1012
DATACATEGORY VARCHAR;
IS_FROM_AWS_FEED BOOLEAN;
RECORD_COUNT number;
DaysUntilVulConsideredDeleted number;

BEGIN
select DATACATEGORY,IS_FROM_AWS_FEED into :DATACATEGORY,:IS_FROM_AWS_FEED FROM CORE.SNAPSHOT_IDS where SNAPSHOT_ID = :P_SNAPSHOT_ID;
Appl := :Appl || ''('' || DATACATEGORY || '')''; -- This helps to clarify which VUL we are processing
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

-- 241023 CR1012 added MAG_VUL_MITIGATED
IF (upper(:DATACATEGORY) NOT IN (:AWS_VUL_MITIGATED,:CCIC_VUL_MITIGATED,:MAG_VUL_MITIGATED)) THEN
	BEGIN
	Msg := ''DataCategory not vaild in this stored procedure'';
	CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    CALL CORE.SP_CRM_END_PROCEDURE (:Appl);
	RETURN :Msg;
	END;
END IF;

BEGIN TRANSACTION;
--
-- Logically delete vulnerabilities that have not been marked as fixed in (DaysUntilVulConsideredDeleted) days
--
DaysUntilVulConsideredDeleted := (select PARMINT FROM CORE.CONFIG where PARMNAME = ''DaysUntilVulConsideredDeleted'');

If (DaysUntilVulConsideredDeleted IS NULL) THEN
	BEGIN
	Msg := ''WARNING: Config parameter (DaysUntilVulConsideredDeleted) not available'';
	CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
	END;
Else
    BEGIN
    --
    -- Age vulnerabilities that are not already fixed
    --
    UPDATE CORE.VULPLUGINS_MASTER
    set dateDeleted = CURRENT_TIMESTAMP()
    ,DeletionReason = ''More than '' || :DaysUntilVulConsideredDeleted::varchar || '' days since lastFound''
    ,IS_PREV_DELETED = TRUE
    ,DATEMODIFIED = CURRENT_TIMESTAMP() -- DATEMODIFIED. Setting this is critical to SP_CRM_UPDATE_VULCVE_MASTER
    WHERE DeletionReason IS NULL and MitigationStatus <> ''fixed''
    and DATEDIFF(d,lastfound,CURRENT_TIMESTAMP()) > :DaysUntilVulConsideredDeleted;

    RECORD_COUNT := SQLROWCOUNT;
    Msg := ''VULPLUGINS_MASTER records logically deleted(>'' || :DaysUntilVulConsideredDeleted::varchar || '' days)='' || RECORD_COUNT::varchar;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
End if;

COMMIT;


BEGIN TRANSACTION;

UPDATE CORE.VULPLUGINS_MASTER upd
set MITIGATIONSTATUS = ''fixed''
,DATEMITIGATED = CURRENT_TIMESTAMP()
,DATEMODIFIED = CURRENT_TIMESTAMP() -- DATEMODIFIED. Setting this is critical to SP_CRM_UPDATE_VULCVE_MASTER
FROM CORE.VULPLUGINS_MASTER vp
JOIN (select dw_asset_id,plugin_id,max(last_seen) as MAX_LASTSEEN
    FROM CORE.RAW_TENABLE_VUL
    WHERE snapshot_id = :P_SNAPSHOT_ID
    and severity_id > 0 -- Do not use Informational records (severity_id = 0)
    group by dw_asset_id,plugin_id) mit on mit.dw_asset_id = vp.dw_asset_id and mit.plugin_id = vp.plugin_id
WHERE upd.DW_PLUGIN_VUL_ID = vp.DW_PLUGIN_VUL_ID and mit.MAX_LASTSEEN >= vp.LASTFOUND
and coalesce(vp.MITIGATIONSTATUS,''itsnull'') <> ''fixed'' -- Dont mark as fixed if already fixed
and vp.DELETIONREASON IS NULL; -- Dont mark as fixed if already deleted

RECORD_COUNT := SQLROWCOUNT;
Msg := ''VULPLUGINS_MASTER records just marked as fixed='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

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
END;
';