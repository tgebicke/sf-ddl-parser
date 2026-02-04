CREATE OR REPLACE PROCEDURE "SP_CRM_CRRPRECHECKS_ROWBYROWCHECK1"()
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
accumulator number;
accumulator1 number;
res RESULTSET DEFAULT (select mcrr."System", mcrr."Total Assets", hwam.assets from rpt.V_CyberRisk_System_Summary mcrr join CORE.VW_SYSTEMSUMMARY HWAM on hwam.acronym = mcrr."System" where HWAM.report_id = (select max(report_id) from core.report_ids where is_endofmonth = 1) and mcrr."Total Assets" != hwam.assets);
cur1 CURSOR FOR res;

res1 RESULTSET DEFAULT (select acronym, mcrr."Total Vulnerabilites" + mcrr."VulMedium" + mcrr."VulLow" as mcrr_Total_Vulnerabilites, VULN.vulcritical + VULN.vulhigh + VULN.vulmedium + VULN.vullow Total_Vulnerabilites, VULN.vulcritical, VULN.vulhigh, mcrr."VulMedium" mcrr_vulmedium, VULN.vulmedium, mcrr."VulLow" mcrr_vullow, VULN.vullow from rpt.V_CyberRisk_System_Summary mcrr JOIN CORE.VW_SYSTEMSUMMARY VULN on VULN.acronym = mcrr."System" where VULN.report_id = (select max(report_id) from core.report_ids where is_endofmonth = 1) and mcrr_Total_Vulnerabilites != Total_Vulnerabilites);
cur2 CURSOR FOR res1;

res2 RESULTSET;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE(:Appl);

CREATE TEMPORARY TABLE temp_Assets (
	AssetMatch varchar);    

FOR row_variable IN cur1 DO
          accumulator := accumulator + row_variable.a;
      END FOR;

FOR row_variable IN cur2 DO
          accumulator1 := accumulator1 + row_variable.a;
      END FOR;    

if (accumulator is NULL and accumulator1 is NULL) then 
    INSERT INTO temp_Assets (AssetMatch) VALUES (''Asset counts Matched successfully'');
    INSERT INTO temp_Assets (AssetMatch) VALUES (''Vulnerability counts Matched successfully'');
    res2 := (select * from temp_Assets);

elseif (accumulator is NULL and accumulator1 > 0) then  
    INSERT INTO temp_Assets (AssetMatch) VALUES (''Asset counts Matched successfully'');
    INSERT INTO temp_Assets (AssetMatch) VALUES (''Vulnerability counts did not Match'');
    res2 := (select * from temp_Assets);
 
elseif (accumulator > 0 and accumulator1 is NULL) then
   INSERT INTO temp_Assets (AssetMatch) VALUES (''Asset counts did not Match'');
   INSERT INTO temp_Assets (AssetMatch) VALUES (''Vulnerability counts Matched successfully'');
   res2 := (select * from temp_Assets);

else 
    INSERT INTO temp_Assets (AssetMatch) VALUES (''Both Assets and Vulnerability counts are not Matched'');
   res2 := (select * from temp_Assets);

end if;
drop table temp_Assets;
CALL CORE.SP_CRM_END_PROCEDURE(:Appl);


    
RETURN TABLE(res2);

   


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