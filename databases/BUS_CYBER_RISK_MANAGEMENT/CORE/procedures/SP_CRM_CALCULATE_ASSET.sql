CREATE OR REPLACE PROCEDURE "SP_CRM_CALCULATE_ASSET"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Calculate Asset procedure'
EXECUTE AS OWNER
AS 'DECLARE
Appl varchar := ''SP_CRM_CALCULATE_ASSET'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
Unknown varchar := ''Unknown''; -- CR1037 241125
RECORD_COUNT number;
BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);



--
-- CR1037 241125 Merged SP_CRM_DETERMINE_DEVICETYPE_V2 into this stored procedure
--
----------------------------------------------------------------------------------------------
--
--          DETERMINE DW_DERIVED_DEVICETYPE
--
----------------------------------------------------------------------------------------------

BEGIN TRANSACTION;
--
-- Always re-evaluate DW_DERIVED_DEVICETYPE since OS or other factors may change
--
update CORE.ASSET
set DW_DERIVED_DEVICETYPE = :Unknown
where Is_Applicable=1;
COMMIT;

BEGIN TRANSACTION;
update CORE.ASSET
set DW_DERIVED_DEVICETYPE  = ''Firewall''
where Is_Applicable=1 and DW_DERIVED_DEVICETYPE = :Unknown
and NULLIF(OS,'''') is not null -- OS
and lower(OS) like ''%pan-os%'';
COMMIT;

BEGIN TRANSACTION;
update CORE.ASSET
set DW_DERIVED_DEVICETYPE  = ''Laptop''
where Is_Applicable=1 and DW_DERIVED_DEVICETYPE = :Unknown 
and NULLIF(OS,'''') is not null -- OS
and (lower(OS) like ''%windows 10%'' 
-- 241125 CR1037    or lower(DEVICEMODEL) like ''%macbookpro%'' or lower(DEVICEMODEL) like ''%latitude%''
-- 241121 CR1037    or lower(OS) = ''windows'' 
-- 241121 CR1037    or lower(OS) = ''microsoft windows'' 
    or lower(OS) = ''microsoft windows 7'' or lower(OS) = ''microsoft windows 98''
    or lower(OS) = ''microsoft windows vista''
    or lower(OS) like ''%windows 11%''
    or OS = ''Sonoma (14)'' -- MacOS
    or lower(OS) like ''%apple macos%''
    or OS = ''Mac OS X 10.4''
    or OS = ''Sequoia (15)'' -- MacOS
    );
COMMIT;

BEGIN TRANSACTION;
update CORE.ASSET
set DW_DERIVED_DEVICETYPE = ''Load Balancer''
where Is_Applicable=1 and DW_DERIVED_DEVICETYPE = :Unknown
    and NULLIF(OS,'''') is not null -- OS
    and (lower(OS) like ''%f5 networks big-ip%'' or OS = ''Citrix NetScaler''
        or OS = ''F5 BIG-IP Local Traffic Manager load balancer''
        );
COMMIT;

BEGIN TRANSACTION;
update CORE.ASSET
set DW_DERIVED_DEVICETYPE = ''Router or Switch''
where Is_Applicable=1 and DW_DERIVED_DEVICETYPE = :Unknown
and NULLIF(OS,'''') is not null -- OS
and (lower(OS) like ''%cisco%'' or lower(OS) like ''%brocade switch%'' or lower(OS) like ''%fortios%'');
COMMIT;

BEGIN TRANSACTION;
update CORE.ASSET
set DW_DERIVED_DEVICETYPE = ''Server''
where Is_Applicable=1 and DW_DERIVED_DEVICETYPE = :Unknown
and (
    (NULLIF(OS,'''') is not null -- OS
        and (lower(OS) like ''%server%'' or lower(OS) like ''%aix%'' or lower(OS) like ''%centos%'' or lower(OS) like ''%freebsd%''
            or lower(OS) like ''%redhat%'' or lower(OS) like ''%red hat%'' or lower(OS) like ''%linux%'' or lower(OS) like ''%esxi%'' 
            or lower(OS) like ''%solaris%'' or lower(OS) = ''unix''
            or lower(OS) like ''%win2016 10%'' or lower(OS) like ''%win2019 10%'' or lower(OS) like ''%windows nt%''
            or lower(OS) like ''%microsoft windows 2000%''
            or lower(OS) = ''suse''
            or lower(OS) like ''%hp-ux%''
            or lower(OS) like ''ubuntu%''
            )
    )
    OR
    (NULLIF(OS_CPE,'''') is not null -- OS_CPE
        and (lower(OS_CPE) like ''%server%''
            )
    )
    OR 
    (NULLIF(DEVICEMODEL,'''') is not null -- DEVICEMODEL
        and (lower(DEVICEMODEL) like ''%ucsc-c220-m%'' or lower(DEVICEMODEL) like ''%ucsc-c240-m%'' or lower(DEVICEMODEL) like ''%poweredge%''
        )
    )
    OR
    (NULLIF(OS_VERSION,'''') is not null -- OS_VERSION
        and (lower(OS_VERSION) like ''%server%'' 
        )
    )
);
COMMIT;
  
BEGIN TRANSACTION;
--
-- 241122 CR1038 as per Teresa, Taggable assets are considered Endpoints but Vulnerability scan data does not necessarily indicate Endpoint
--
update CORE.ASSET
set DW_DERIVED_DEVICETYPE = ''Unknown endpoint''
where Is_Applicable=1 and DW_DERIVED_DEVICETYPE = :Unknown and NULLIF(ASSET_ID_TATTOO,'''') IS NOT NULL;
-- 241122 CR1038 and (NULLIF(ASSET_ID_TATTOO,'''') IS NOT NULL or LASTSEEN_VUL IS NOT NULL);
COMMIT;

BEGIN TRANSACTION;
update CORE.ASSET
set DW_DERIVED_DEVICETYPE = ''Unknown Windows''
where Is_Applicable=1 and DW_DERIVED_DEVICETYPE = :Unknown and lower(OS) like ''%windows%'';
COMMIT;

----------------------------------------------------------------------------------------------
--
--          DETERMINE DEVICETYPE
--
----------------------------------------------------------------------------------------------

BEGIN TRANSACTION;
--
-- When ASSET.DEVICETYPE is not in DEVICETYPES (master) set to Unknown
--
update CORE.ASSET upd
set DEVICETYPE = :Unknown
FROM CORE.ASSET a
LEFT OUTER JOIN (select DISTINCT DEVICETYPE FROM CORE.DEVICETYPES) dt on dt.DEVICETYPE = a.DEVICETYPE
where a.Is_Applicable=1 and a.dw_asset_id = upd.dw_asset_id and dt.DEVICETYPE is null;
COMMIT;
--
-- Set DEVICETYPE to DW_DERIVED_DEVICETYPE when DEVICETYPE is any form of unknown (See DeviceTypes table)
--
BEGIN TRANSACTION;
update CORE.ASSET
set DEVICETYPE = DW_DERIVED_DEVICETYPE
where Is_Applicable=1 and lower(DEVICETYPE) like ''%unknown%'' and DW_DERIVED_DEVICETYPE <> :Unknown;

RECORD_COUNT := SQLROWCOUNT;
Msg := ''DeviceType changes made='' || :RECORD_COUNT;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);
COMMIT;


/******************     FUTURE: USE FORESCOUT_DEVICETYPE,TENABLE_DEVICETYPE  
************************************************************************/








----------------------------------------------------------------------------------------------
--
--            CALCULATE BOOLEANS
--
----------------------------------------------------------------------------------------------

BEGIN TRANSACTION;

UPDATE CORE.ASSET t
set Is_Scannable = 1
FROM CORE.ASSET a
join CORE.DEVICETYPES dt on dt.DEVICETYPE = a.DEVICETYPE
where t.DW_ASSET_ID = a.DW_ASSET_ID and a.Is_Applicable = 1 and a.Is_Scannable = 0 and (dt.Is_Scannable = 1 or a.LastSeen_VUL IS NOT NULL);

UPDATE CORE.ASSET t
set Is_Tattooable = 1
FROM CORE.ASSET a
join CORE.DEVICETYPES dt on dt.DEVICETYPE = a.DEVICETYPE
where t.DW_ASSET_ID = a.DW_ASSET_ID and a.Is_Applicable = 1 and a.Is_Tattooable = 0 and (dt.Is_Tattooable = 1 or a.asset_id_tattoo IS NOT NULL);

-- 241127 TESTING PROOF OF CONCEPT
UPDATE CORE.ASSET
set IS_ENDPOINT = 1
WHERE Is_Applicable = 1 and asset_id_tattoo IS NOT NULL;

COMMIT;


----------------------------------------------------------------------------------------------
--
--          CALCULATE NUMERICAL VALUES
--
----------------------------------------------------------------------------------------------

BEGIN TRANSACTION;

-- 231012 changed from CVSSV2BASESCORE to CVSSV3BASESCORE
Update CORE.ASSET
set VulnRiskTolerance = v.NUMERATOR / v.DENOMINATOR
FROM (select a.DW_ASSET_ID
    ,SUM(IFF(v.DW_VUL_ID is null,0,v.DaysSinceDiscovery * v.CVSSV3BASESCORE * s.OATO_Category * IFF(v.exploitAvailable=''Yes'',2,1)))::FLOAT as NUMERATOR
    ,(IFF(count(1)=0,1,count(1)))::float as DENOMINATOR
    FROM CORE.VW_ASSETS a 
    LEFT JOIN CORE.VW_VulMaster v on a.DW_ASSET_ID = v.DW_ASSET_ID and LOWER(v.MitigationStatus) IN (''open'',''reopened'')
    LEFT JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
    WHERE a.Is_Scannable=1 
    group by a.DW_ASSET_ID) v
WHERE v.DW_ASSET_ID = CORE.ASSET.DW_ASSET_ID;

COMMIT;

BEGIN TRANSACTION;
--250226 - ADD BETA_VulnRiskTolerance FROM  BUS_CYBER_RISK_MANAGEMENT.CORE.SEC_VW_VUL_RISK_TOLERANCE VIEW

UPDATE BUS_CYBER_RISK_MANAGEMENT.CORE.ASSET A
SET A.BETA_VulnRiskTolerance = V.VULRISKFACTOR
FROM  (
    SELECT
        a.DW_ASSET_ID,
        SUM(v.VULRISKFACTOR) AS VULRISKFACTOR
    FROM BUS_CYBER_RISK_MANAGEMENT.CORE.SEC_VW_VUL_RISK_TOLERANCE v
    LEFT JOIN BUS_CYBER_RISK_MANAGEMENT.CORE.VW_ASSETS a ON a.DW_ASSET_ID = v.DW_ASSET_ID
    GROUP BY a.DW_ASSET_ID
) V
WHERE V.DW_ASSET_ID = A.DW_ASSET_ID;

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
END';