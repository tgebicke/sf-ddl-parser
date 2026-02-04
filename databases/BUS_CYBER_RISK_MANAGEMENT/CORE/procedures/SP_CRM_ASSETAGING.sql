CREATE OR REPLACE PROCEDURE "SP_CRM_ASSETAGING"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Delete asset (device) from MDR (Asset table) when there has been no CDM activity in over x days.'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_ASSETAGING'';
DataCategory varchar;
RECORD_COUNT number;
AssetAgingDefaultCutoff number;
AssetAgingCloudCutoff number;
DeletionReason varchar;
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
BEGIN

CALL CORE.SP_CRM_START_PROCEDURE(:Appl);

AssetAgingDefaultCutoff := (select PARMINT FROM CORE.Config where ParmName = ''AssetAgingDefaultCutoff'');
AssetAgingCloudCutoff := (select PARMINT FROM CORE.Config where ParmName = ''AssetAgingCloudCutoff'');

IF (:AssetAgingDefaultCutoff = 0 or :AssetAgingCloudCutoff = 0) THEN
    Msg := ''WARNING: Config parameter not available'';
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    COMMIT;
    return Msg;
END IF;

--
-- Write all deletion candidates to the TEMP_ASSETS_TO_DELETE table
--

BEGIN TRANSACTION;
--
-- We expect the AWS datastream to always have the most current list of assets.
-- To be certain, if there was no change to LAST_CONFIRMED_TIME delete this AWS asset.
--
DeletionReason := ''AWS Asset deleted (not seen in latest download)'';
INSERT INTO CORE.TEMP_ASSETS_TO_DELETE (DW_ASSET_ID,DELETIONREASON,INSERT_DATE,IS_PHYSICAL_DELETE) -- 240816 CR-TBD add IS_PHYSICAL_DELETE
SELECT DW_ASSET_ID,:DeletionReason,CURRENT_TIMESTAMP,0 FROM ASSET
WHERE Is_Applicable = 1 and IS_FROM_AWS_FEED = TRUE and PREV_LAST_CONFIRMED_TIME = LAST_CONFIRMED_TIME;
RECORD_COUNT := SQLROWCOUNT;
Msg := DeletionReason || ''='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
COMMIT;

BEGIN TRANSACTION;
--
-- Age cloud assets
--
DeletionReason := ''AWS Asset deleted (last_confirmed_time >'' || :AssetAgingCloudCutoff || '' days)'';
INSERT INTO CORE.TEMP_ASSETS_TO_DELETE (DW_ASSET_ID,DELETIONREASON,INSERT_DATE,IS_PHYSICAL_DELETE) -- 240816 CR-TBD add IS_PHYSICAL_DELETE
SELECT DW_ASSET_ID,:DeletionReason,CURRENT_TIMESTAMP,0 FROM ASSET
WHERE DATEDIFF(day,last_confirmed_time,current_date()) > :AssetAgingCloudCutoff and Is_Applicable = 1 and IS_FROM_AWS_FEED = TRUE;
RECORD_COUNT := SQLROWCOUNT;
Msg := DeletionReason || ''='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
COMMIT;

BEGIN TRANSACTION;
--
-- Age on-prem assets or default
--
DeletionReason := ''On-Prem Asset deleted (last_confirmed_time >'' || :AssetAgingDefaultCutoff || '' days)'';
BEGIN TRANSACTION;
INSERT INTO CORE.TEMP_ASSETS_TO_DELETE (DW_ASSET_ID,DELETIONREASON,INSERT_DATE,IS_PHYSICAL_DELETE) -- 240816 CR-TBD add IS_PHYSICAL_DELETE
SELECT DW_ASSET_ID,:DeletionReason,CURRENT_TIMESTAMP,0 FROM ASSET
WHERE DATEDIFF(day,last_confirmed_time,current_date()) > :AssetAgingDefaultCutoff and Is_Applicable = 1 and IS_FROM_AWS_FEED = FALSE;

RECORD_COUNT := SQLROWCOUNT;
Msg := DeletionReason || ''='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
COMMIT;

BEGIN TRANSACTION;
--
-- 240818 CR-TBD
--
-- Physically delete (in-active) AWS or on-prem assets more than 20 days old
--
DeletionReason := ''AWS/On-Prem (In-active) Asset deleted (last_confirmed_time > 20 days)'';
BEGIN TRANSACTION;
INSERT INTO CORE.TEMP_ASSETS_TO_DELETE (DW_ASSET_ID,DELETIONREASON,INSERT_DATE,IS_PHYSICAL_DELETE)
SELECT DW_ASSET_ID,:DeletionReason,CURRENT_TIMESTAMP,1 FROM ASSET
WHERE DATEDIFF(day,last_confirmed_time,current_date()) > 20 and Is_Applicable = 0;

RECORD_COUNT := SQLROWCOUNT;
Msg := DeletionReason || ''='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
COMMIT;


CALL CORE.SP_CRM_DELETE_ASSET(); -- 240816 CR-TBD NEW


CALL CORE.SP_CRM_END_PROCEDURE(:Appl);
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