CREATE OR REPLACE PROCEDURE "SP_UPDATE_HWAM_MONTHLY_DATA"()
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
COMMENT='Save IUSG-AWS HWAM data of last day of every month from APP_CDM'
EXECUTE AS OWNER
AS '
    var Sql_insert = `Insert into CORE.OATO_HWAM_MONTHLY_DATA
                      select  INSTANCEID,
                              INSTANCESTATUS,
                              ACCOUNT_NUMBER,
                              PRIMARY_FISMA_ID_DERIVED,
                              DATACENTER_ID_DERIVED,
                              SYSTEM_ACRONYM,
                              LAST_CONFIRMED_TIME,
                              current_date() 
                      from APP_CDM.SHARED.SEC_VW_HWAM_AWS;  -- 231031 rename of DB (was CDM) RBAC 20230809 change to SHARED
                      `;
      
    snowflake.execute (
            {sqlText: Sql_insert}
            );
    return ''OATO_HWAM_MONTHLY_DATA updated successful'';
   ';