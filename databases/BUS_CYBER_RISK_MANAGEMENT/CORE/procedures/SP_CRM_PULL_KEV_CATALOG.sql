CREATE OR REPLACE PROCEDURE "SP_CRM_PULL_KEV_CATALOG"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Pull CISA Known Exploited Vulnerabilities(KEV) data into BUS_CYBER_RISK_MANAGEMENT. https://www.cisa.gov/known-exploited-vulnerabilities-catalog'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_PULL_KEV_CATALOG'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
TheRowCount NUMBER := 0;
BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

select count(1) into :TheRowCount FROM REF_LOOKUPS.SHARED.SEC_MV_BOD_KEV; -- 230801 was in BOD_KEV_CATALOG schema  -- 230811 added SEC_

IF (TheRowCount = 0) THEN
	BEGIN
    CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,''WARNING: REF_LOOKUPS.SHARED.SEC_MV_BOD_KEV is empty'');   -- 230811 added SEC_
    END;
ELSE
    BEGIN
    BEGIN TRANSACTION;
    
    MERGE INTO CORE.KEV_CATALOG t USING (
    SELECT
        kevdetail.DUEDATE as BODDUEDATE
	    ,kevdetail.CVEID as CVE
        ,kevdetail.DATEADDED as DATEADDEDTOCATALOG
	    ,kevdetail.PRODUCT
        ,kevdetail.REQUIREDACTION
        ,kevdetail.SHORTDESCRIPTION
        ,kevdetail.VENDORPROJECT
        ,kevdetail.VULNERABILITYNAME
    FROM REF_LOOKUPS.SHARED.SEC_MV_BOD_KEV kevdetail
    --
    -- 240919 1059 CR982
    -- It is expected that the NIST NVD (nvd.nist.gov) contains distinct CVEs but on 9/19/24, CVE-2019-1069 was found to be duplicated.
    -- This caused a failure in this stored procedure. We will now use the record with the greatest DUEDATE. 
    --
    JOIN (SELECT r2.CVEID,r2.DUEDATE
        FROM (select rank()over(partition by r1.CVEID order by r1.DUEDATE desc) TheRank,r1.CVEID,r1.DUEDATE
            FROM REF_LOOKUPS.SHARED.SEC_MV_BOD_KEV r1
            JOIN (select DISTINCT CVEID FROM REF_LOOKUPS.SHARED.SEC_MV_BOD_KEV) d on d.CVEID = r1.CVEID) r2
            where r2.TheRank = 1) UniqueKev on UniqueKev.CVEID = kevdetail.CVEID and UniqueKev.DUEDATE = kevdetail.DUEDATE
    )s ON (s.CVE = t.CVE)
    WHEN MATCHED THEN UPDATE SET 
        t.BODDUEDATE = s.BODDUEDATE
        ,t.DATEADDEDTOCATALOG = s.DATEADDEDTOCATALOG
        ,t.DATEMODIFIED = CURRENT_TIMESTAMP()
        ,t.PRODUCT = s.PRODUCT
        ,t.REQUIREDACTION = s.REQUIREDACTION
        ,t.SHORTDESCRIPTION = s.SHORTDESCRIPTION
        ,t.VENDORPROJECT = s.VENDORPROJECT
        ,t.VULNERABILITYNAME = s.VULNERABILITYNAME
    WHEN NOT MATCHED THEN INSERT
        (BODDUEDATE
        ,CVE
        ,DATEADDEDTOCATALOG
        ,INSERT_DATE
        ,IS_DELETED
        ,NOTES
        ,ORIG_DUEDATE
        ,PRODUCT
        ,REQUIREDACTION
        ,SHORTDESCRIPTION
        ,VENDORPROJECT
        ,VULNERABILITYNAME
    )
    VALUES (s.BODDUEDATE
        ,s.CVE
        ,s.DATEADDEDTOCATALOG
        ,CURRENT_TIMESTAMP() -- INSERT_DATE
        ,0 -- IS_DELETED
        ,null -- NOTES
        ,s.BODDUEDATE -- ORIG_DUEDATE
        ,s.PRODUCT
        ,s.REQUIREDACTION
        ,s.SHORTDESCRIPTION
        ,s.VENDORPROJECT
        ,s.VULNERABILITYNAME
    );

   -- 230922 Msg := ''Merge KEV_CATALOG complete'';
   -- 230922 CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

    COMMIT;

    BEGIN TRANSACTION;
    --
    -- Logically delete the KEV if no longer in new catalog
    -- We keep the deleted KEV for use in vulnerability history
    --
    UPDATE CORE.KEV_CATALOG upd
    set IS_DELETED = 1
    ,DATEDELETED = CURRENT_TIMESTAMP()
    from CORE.KEV_CATALOG oldkev
    left outer join REF_LOOKUPS.SHARED.SEC_MV_BOD_KEV newkev on newkev.cveid = oldkev.CVE -- 230801 was in BOD_KEV_CATALOG schema  -- 230811 added SEC_
    WHERE upd.ID = oldkev.ID and newkev.cveid IS NULL and oldkev.IS_DELETED = 0;

    COMMIT;
    
    /* 231103 
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
    */

    
	END;
END IF;

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