CREATE OR REPLACE PROCEDURE "SP_CRM_PULL_TENABLE_SOFTWARE_V2"("P_SNAPSHOT_ID" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Stored procedure used to populate CORE.ASSET_SOFTWARE table'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_PULL_TENABLE_SOFTWARE_V2'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
False boolean := 0;
True boolean := 1;
RECORD_COUNT NUMBER;
DATACATEGORY VARCHAR;
IS_FROM_AWS_FEED BOOLEAN;
SOURCETOOL varchar := ''Tenable'';
PLUGIN_20811_COUNT NUMBER := 0;
PLUGIN_22869_COUNT NUMBER := 0;
PLUGIN_45590_COUNT NUMBER := 0;

--
-- CONCEPT: Extract (DW_ASSET_ID, PLUGIN_ID, RAW_PRODUCT, SOURCE_TOOL, SNAPSHOT_ID) regardless of PLUGIN_ID.
--          Then obtain PRODUCT_NAME, DATE_INSTALLED, VERSION from RAW_PRODUCT. 
-- It is preferable to write directly to the ASSET_SOFTWARE table but there are more plugins that need to be included
-- and many unknowns about the parsing and cleaning of the data. Therefore, we will continue to write to the
--
--
-- Plugin 22869	Software Enumeration (SSH)
-- Plugin 20811	Microsoft Windows Installed Software Enumeration (credentialed check)
-- Plugin 45590 Common Platform Enumeration (CPE)

BEGIN
select DATACATEGORY,IS_FROM_AWS_FEED into :DATACATEGORY,:IS_FROM_AWS_FEED FROM CORE.SNAPSHOT_IDS where SNAPSHOT_ID = :P_SNAPSHOT_ID;
Appl := :Appl || ''('' || DATACATEGORY || '')''; -- This helps to clarify which VUL we are processing
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

--TRUNCATE CORE.TEMP_ASSET_SOFTWARE;


--
-- Plugin 20811
--
-- General Format of plugin
--      <plugin_output> (All plugins start with this)
--      Preamble ("The following software are installed on the remote host :"), Ths is the same for AWS and CCIC
--      List of software (See notes about deliminator below)
--      Installed updates title ("The following updates are installed :"))
--      List of installed updates (See notes about deliminator below)
--      </plugin_output> (All plugins end with this)
--
-- Actual Finding in one plugintext (The 2nd set of software and updates are identical)
--      <plugin_output>
--      The following software are installed on the remote host :
--      List of software...
--      The following updates are installed :
--      List of updates...
--      The following software are installed on the remote host :
--      List of software...
--      The following updates are installed :
--      List of updates...
--      </plugin_output>
--
-- 1) For CCIC VUL each software is delineated with a Line-Feed character chr(10)
-- 2) For AWS VUL each software is NOT delineated with a Line-Feed character chr(10)
-- 3) For CCIC AND AWS a right-bracket chr(93) can be used to delineate the software IF the
--      version/install date format is replaced. 
--      e.g [version 12.16.2020.01]  [installed on 2024/04/29]; The "] [" is replaced with 2 back-to-back characters that are
--      highly unlikely to occur naturally in the data (see VERSION_DELIMINATOR)
-- 4) Install date is not always present
-- 5) At this time we do not want the list of updates
-- 6) Sometimes the software version does not have the version tag leaving us to determine the version as part of parsing
--

IF (:DATACATEGORY = ''CCIC VUL'') THEN
    BEGIN
    BEGIN TRANSACTION;
    INSERT INTO CORE.TEMP_ASSET_SOFTWARE
    (
    DW_ASSET_ID,
    PLUGIN_ID,
    RAW_PRODUCT,
    SOURCE_TOOL,
    SNAPSHOT_ID
    )
    SELECT t.DW_ASSET_ID,t.PLUGIN_ID,t.RAW_PRODUCT,:SOURCETOOL as SOURCE_TOOL,:P_SNAPSHOT_ID
    FROM (
    select r.dw_asset_id,r.PLUGIN_ID
    ,split_part(plugintext,''The following software are installed on the remote host :'',2) as PREAMBLE_REMOVED
    ,split_part(PREAMBLE_REMOVED,''The following updates are installed'',1) as UPDATES_REMOVED
    ,split_part(UPDATES_REMOVED,''</plugin_output>'',1) as USABLE_PLUGINTEXT
    ,ARRAY_DISTINCT(STRTOK_TO_ARRAY(USABLE_PLUGINTEXT,CHR(10))) as SOFTARRAY
    ,NULLIF(TRIM(REPLACE(f.value::string,CHR(10),'''')),'''') as RAW_PRODUCT
    FROM CORE.RAW_TENABLE_VUL r
    JOIN CORE.ASSET a on a.DW_ASSET_ID = r.DW_ASSET_ID and a.IS_APPLICABLE = 1 -- We only want active assets
    join table(flatten(SOFTARRAY,outer=>true)) as f
    where r.SNAPSHOT_ID = :P_SNAPSHOT_ID 
    and r.DW_ASSET_ID IS NOT NULL 
    and r.PLUGIN_ID = ''20811'' -- Microsoft Windows Installed Software Enumeration (credentialed check)
    and NULLIF(TRIM(RAW_PRODUCT),'''') IS NOT NULL -- Must be non-null
    and RAW_PRODUCT NOT like ''%version Primary_FISMA_ID%'' -- Exclude asset tags
    and RAW_PRODUCT NOT like ''%version Dependent_FISMA_ID%'' -- Exclude asset tags
    and RAW_PRODUCT NOT like ''%version Asset_ID%'' -- Exclude asset tags
    and RAW_PRODUCT NOT REGEXP ''.*KB[0-9]{1,7}.*'' -- Exclude Windows KB; Note: In the future these might be included
    and NOT REGEXP_LIKE(RAW_PRODUCT,''[{][A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}[{] .*'') -- {F38DB479-C9A3-412F-83C8-09DFF5BBC210}
    ) t
    WHERE NULLIF(t.RAW_PRODUCT,'''') IS NOT NULL;

    PLUGIN_20811_COUNT := SQLROWCOUNT;
    COMMIT;
    END;
ELSE -- AWS VUL/AWS VUL MITIGATED/MAG VUL/MAG VUL MITIGATED
    BEGIN
    BEGIN TRANSACTION;
    INSERT INTO CORE.TEMP_ASSET_SOFTWARE
    (
    DW_ASSET_ID,
    PLUGIN_ID,
    RAW_PRODUCT,
    SOURCE_TOOL,
    SNAPSHOT_ID
    )
    SELECT t.DW_ASSET_ID,t.PLUGIN_ID,t.RAW_PRODUCT,:SOURCETOOL as SOURCE_TOOL,:P_SNAPSHOT_ID
    FROM (
    select r.dw_asset_id,r.PLUGIN_ID
    ,split_part(plugintext,''The following software are installed on the remote host :'',2) as PREAMBLE_REMOVED
    ,split_part(PREAMBLE_REMOVED,''The following updates are installed'',1) as UPDATES_REMOVED
    ,split_part(UPDATES_REMOVED,''</plugin_output>'',1) as USABLE_PLUGINTEXT
    ,REPLACE(USABLE_PLUGINTEXT,'']  [installed on'',(CHR(9) || ''installed on'')) as READY_FOR_ARRAY
    ,ARRAY_DISTINCT(STRTOK_TO_ARRAY(READY_FOR_ARRAY,'']'')) as SOFTARRAY
    ,NULLIF(TRIM(f.value::string),'''') as RAW_PRODUCT
    FROM CORE.RAW_TENABLE_VUL r
    JOIN CORE.ASSET a on a.DW_ASSET_ID = r.DW_ASSET_ID and a.IS_APPLICABLE = 1 -- We only want active assets
    join table(flatten(SOFTARRAY,outer=>true)) as f
    where r.SNAPSHOT_ID = :P_SNAPSHOT_ID 
    and r.DW_ASSET_ID IS NOT NULL 
    and r.PLUGIN_ID = ''20811'' -- Microsoft Windows Installed Software Enumeration (credentialed check)
    and NULLIF(TRIM(RAW_PRODUCT),'''') IS NOT NULL -- Must be non-null
    and RAW_PRODUCT NOT like ''%version Primary_FISMA_ID%'' -- Exclude asset tags
    and RAW_PRODUCT NOT like ''%version Dependent_FISMA_ID%'' -- Exclude asset tags
    and RAW_PRODUCT NOT like ''%version Asset_ID%'' -- Exclude asset tags
    and RAW_PRODUCT NOT REGEXP ''.*KB[0-9]{1,7}.*'' -- Exclude Windows KB; Note: In the future these might be included
    and NOT REGEXP_LIKE(RAW_PRODUCT,''[{][A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}[{] .*'') -- {F38DB479-C9A3-412F-83C8-09DFF5BBC210}
    ) t
    ;

    PLUGIN_20811_COUNT := SQLROWCOUNT;
    COMMIT;
    END;
END IF;

If (PLUGIN_20811_COUNT > 0) THEN
    BEGIN
    Msg := ''TEMP_ASSET_SOFTWARE(pluginid 20811) Written='' || :PLUGIN_20811_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
    END;
END IF;



--
-- Remove Line-Feed from PRODUCT_NAME
-- Dont change RAW_DATEINSTALLED below. This will help diagnose future unexpected date formats.
-- 250102 added NULLIF
--
UPDATE CORE.TEMP_ASSET_SOFTWARE
set PRODUCT_NAME = trim(REPLACE(SPLIT_PART(RAW_PRODUCT,''['',1),CHR(10),''''))
,RAW_DATEINSTALLED = NULLIF(trim(REPLACE(SPLIT_PART(RAW_PRODUCT,''installed on '',2),'']'','''')),'''')
,RAW_VERSION = nullif(trim(replace(split_part(split_part(split_part(RAW_PRODUCT,''[version'',2),'']'',1),''installed on'',1)
,'']'','''')),'''')
,DATA_WARNING_ARRAY = ARRAY_CONSTRUCT()
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID;

----------------------------------------------------------------------------------
--
-- Resolve version that does not fit standard format e.g. [version
--
----------------------------------------------------------------------------------

--
-- 01/01/2013 11.0.6.6840
--
UPDATE CORE.TEMP_ASSET_SOFTWARE
set RAW_VERSION = nullif(split_part(RAW_VERSION,'' '',2),'''')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and REGEXP_LIKE(RAW_VERSION,''[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} .*'');

--
-- 250115 resolve version that does not fit standard format e.g. [version
-- Remove version from PRODUCT_NAME
--
UPDATE TEMP_ASSET_SOFTWARE
set PRODUCT_NAME = TRIM(SUBSTRING(PRODUCT_NAME,1,position('' version '',lower(PRODUCT_NAME))))
,RAW_VERSION = NULLIF(TRIM(SUBSTRING(PRODUCT_NAME,(position('' version '',lower(PRODUCT_NAME)) + 9))),'''')
where SNAPSHOT_ID = :P_SNAPSHOT_ID and (nullif(RAW_VERSION,'''') is null and lower(PRODUCT_NAME) like ''% version %'');

--
-- FOR NOW, MAKE VERSION = RAW_VERSION
-- THERE ARE OTHER VERSION FORMATS THAT WILL ALSO NEED TO BE PARSED
--
UPDATE CORE.TEMP_ASSET_SOFTWARE
set VERSION = NULLIF(RAW_VERSION,'''')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and NULLIF(RAW_VERSION,'''') IS NOT NULL;

--------------------------------------------------------------------------
--
-- DETERMINE IF SOFTWARE ALREADY EXISTS
--
--------------------------------------------------------------------------

UPDATE CORE.TEMP_ASSET_SOFTWARE upd
set DW_SWAM_ID = soft.DW_SWAM_ID
FROM CORE.TEMP_ASSET_SOFTWARE newsoft
JOIN CORE.ASSET_SOFTWARE soft on soft.DW_ASSET_ID = newsoft.DW_ASSET_ID and soft.SOFTWARENAME = newsoft.PRODUCT_NAME and soft.VERSION = newsoft.VERSION
WHERE upd.SNAPSHOT_ID = :P_SNAPSHOT_ID and upd.DW_ASSET_ID = newsoft.DW_ASSET_ID 
and newsoft.PRODUCT_NAME IS NOT NULL and newsoft.VERSION IS NOT NULL
and upd.PRODUCT_NAME = newsoft.PRODUCT_NAME and upd.VERSION = newsoft.VERSION;

--------------------------------------------------------------------------
--
-- CONVERT VARIOUS DATEINSTALLED FORMATS
-- NO NEED TO CONVERT DATEINSTALLED IF SOFTWARE ALREADY EXISTS
--
--------------------------------------------------------------------------

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''MM/DD/YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''MM/DD/YYYY'') is not null;

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''MM-DD-YY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''MM-DD-YY'') is not null;

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''YYYY/MM/DD'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''YYYY/MM/DD'') is not null;

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''DD.MM.YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''DD.MM.YYYY'') is not null;

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''MMMM DD, YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''MMMM DD, YYYY'') is not null;

--
-- DO WE ALSO NEED: MM DD YY, HH12:MI AM
--

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''MM/DD/YY, HH12:MI PM'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''MM/DD/YY, HH12:MI PM'') is not null;

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS YYYY'') is not null;

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS CST YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS CST YYYY'') is not null; -- Cant find symbol for TimeZone

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS CDT YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS CDT YYYY'') is not null; -- Cant find symbol for TimeZone

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS EST YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS EST YYYY'') is not null; -- Cant find symbol for TimeZone

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS EDT YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS EDT YYYY'') is not null; -- Cant find symbol for TimeZone

UPDATE TEMP_ASSET_SOFTWARE
set DATEINSTALLED = TO_DATE(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS PDT YYYY'')
WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and RAW_DATEINSTALLED IS NOT NULL and DATEINSTALLED IS NULL
and try_to_date(RAW_DATEINSTALLED,''DY MMMM DD HH24:MI:SS PDT YYYY'') is not null; -- Cant find symbol for TimeZone




---------------------------------------------------------------------------------------------------
-- Check for remaining issues
-- a) RAW_PRODUCT has (installed on) keyword but date was not parsed into raw_dateinstalled
-- b) raw_dateinstalled was populated but could not be converted to date
---------------------------------------------------------------------------------------------------

UPDATE TEMP_ASSET_SOFTWARE
set DATA_WARNING_ARRAY = ARRAY_APPEND(DATA_WARNING_ARRAY,''RAW_DATEINSTALLED not converted'')
where SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and DATEINSTALLED IS NULL 
and (nullif(raw_dateinstalled,'''') is not null or lower(RAW_PRODUCT) like ''%installed on%'');

RECORD_COUNT := SQLROWCOUNT;

If (:RECORD_COUNT > 0) THEN
    BEGIN
    Msg := ''RAW_DATEINSTALLED not converted='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);   
    END;
END IF;

UPDATE TEMP_ASSET_SOFTWARE
set DATA_WARNING_ARRAY = ARRAY_APPEND(DATA_WARNING_ARRAY,''RAW_VERSION not converted='')
where SNAPSHOT_ID = :P_SNAPSHOT_ID and DW_SWAM_ID IS NULL and VERSION IS NULL 
and (nullif(RAW_VERSION,'''') is not null or lower(RAW_PRODUCT) like ''% version%'');

RECORD_COUNT := SQLROWCOUNT;

If (:RECORD_COUNT > 0) THEN
    BEGIN
    Msg := ''RAW_VERSION not converted='' || :RECORD_COUNT;
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);   
    END;
END IF;

Msg := ''Setting Vendor'';
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

BEGIN TRANSACTION;
UPDATE TEMP_ASSET_SOFTWARE 
set VENDOR = ''Citrix''
where SNAPSHOT_ID = :P_SNAPSHOT_ID and UPPER(PRODUCT_NAME) LIKE ''%CITRIX%'';

UPDATE TEMP_ASSET_SOFTWARE 
set VENDOR = ''Cisco''
where SNAPSHOT_ID = :P_SNAPSHOT_ID and UPPER(PRODUCT_NAME) LIKE ''%CISCO%'';

UPDATE TEMP_ASSET_SOFTWARE 
set VENDOR = ''Microsoft''
where SNAPSHOT_ID = :P_SNAPSHOT_ID and UPPER(PRODUCT_NAME) LIKE ''%MICROSOFT%'';

Msg := ''Vendor has been set'';
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
COMMIT;

--------------------------------------------------------------------------
--
-- INSERT/UPDATE CORE.ASSET_SOFTWARE USING CORE.TEMP_ASSET_SOFTWARE
--
--------------------------------------------------------------------------
BEGIN TRANSACTION;
MERGE INTO CORE.ASSET_SOFTWARE as target
USING 
(SELECT MAX(DATEINSTALLED) as DATEINSTALLED,DW_ASSET_ID,PRODUCT_NAME,SOURCE_TOOL,VENDOR,VERSION
    FROM CORE.TEMP_ASSET_SOFTWARE
    WHERE SNAPSHOT_ID = :P_SNAPSHOT_ID
    GROUP BY DW_ASSET_ID,PRODUCT_NAME,SOURCE_TOOL,VENDOR,VERSION
) as src 

ON (src.DW_ASSET_ID = target.DW_ASSET_ID and src.PRODUCT_NAME = target.SOFTWARENAME and src.VERSION = target.VERSION)

WHEN MATCHED THEN UPDATE SET 
    target.LASTSEEN = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (
    DATEINSTALLED
    ,DW_ASSET_ID
    ,FIRSTSEEN
    ,INSERT_DATE
    ,LASTSEEN
    ,MAJOR
    ,MINOR
    ,SOFTWARENAME -- TOBE RENAMED TO PRODUCT_NAME
    ,SOURCE_TOOL
    ,SWAM_CATEGORY
    ,SWAM_SUBCATEGORY
    ,VENDOR
    ,VERSION
)
VALUES (
    src.DATEINSTALLED
    ,src.DW_ASSET_ID
    ,CURRENT_TIMESTAMP() -- FIRSTSEEN
    ,CURRENT_TIMESTAMP() -- INSERT_DATE
    ,CURRENT_TIMESTAMP() -- LASTSEEN
    ,split_part(src.VERSION,''.'',1) -- MAJOR
    ,split_part(split_part(src.VERSION,''.'',2),''.'',1) -- MINOR
    ,src.PRODUCT_NAME
    ,src.SOURCE_TOOL
    ,''TBD'' -- SWAM_CATEGORY
    ,''TBD'' -- SWAM_SUBCATEGORY
    ,src.VENDOR
    ,src.VERSION
);

Msg := ''CORE.ASSET_SOFTWARE updated'';
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
COMMIT;


BEGIN TRANSACTION;
--
-- Update ASSET LASTSEEN_SWAM and SOURCE_TOOL_SWAM
--
UPDATE CORE.ASSET upd
set LASTSEEN_SWAM = sft.LASTSEEN
,SOURCE_TOOL_SWAM = :SOURCETOOL
FROM CORE.ASSET a
JOIN (select DW_ASSET_ID,MAX(LASTSEEN) as LASTSEEN
    from CORE.ASSET_SOFTWARE group by DW_ASSET_ID) sft on sft.DW_ASSET_ID = a.DW_ASSET_ID
WHERE upd.DW_ASSET_ID = a.DW_ASSET_ID;
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