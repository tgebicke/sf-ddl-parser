CREATE OR REPLACE PROCEDURE "SP_CRM_CRRPRECHECKS_ASSETVULCOUNT"()
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
CurSnap number;
PreSnap number;
CurReportId number;
PreReportId number;
CurReportDate datetime;
PreReportDate datetime;
res RESULTSET;
res1 RESULTSET;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE(:Appl);

res:= (select acronym, mcrr."Total Assets" MCRR_Total_Assets, VULN.assets Total_Assets, mcrr."Total Vulnerabilites" + mcrr."VulMedium" + mcrr."VulLow" as mcrr_Total_Vulnerabilites, VULN.vulcritical + VULN.vulhigh + VULN.vulmedium + VULN.vullow Total_Vulnerabilites, mcrr."Critical Vulnerabilities" MCRR_Critical_Vulnerabilities, VULN.vulcritical Critical_Vulnerabilities, mcrr."High Vulnerabilities" MCRR_High_Vulnerabilities, VULN.vulhigh High_Vulnerabilities, mcrr."VulMedium" mcrr_vulmedium, VULN.vulmedium, mcrr."VulLow" mcrr_vullow, VULN.vullow 
from rpt.V_CyberRisk_System_Summary mcrr
JOIN CORE.VW_SYSTEMSUMMARY VULN on VULN.acronym = mcrr."System" where 
VULN.report_id = (select max(report_id) from core.report_ids where is_endofmonth = 1)
UNION
select ''Total'' as acronym, sum(mcrr."Total Assets") MCRR_Total_Assets, sum(VULN.assets) Total_Assets, sum(mcrr."Total Vulnerabilites" + mcrr."VulMedium" + mcrr."VulLow") as mcrr_Total_Vulnerabilites, sum(VULN.vulcritical + VULN.vulhigh + VULN.vulmedium + VULN.vullow) Total_Vulnerabilites, sum(mcrr."Critical Vulnerabilities") MCRR_CRITICAL_VULNERABILITIES, sum(VULN.vulcritical) CRITICAL_VULNERABILITIES, sum(mcrr."High Vulnerabilities") MCRR_HIGH_VULNERABILITIES, sum(VULN.vulhigh) HIGH_VULNERABILITIES, sum(mcrr."VulMedium") mcrr_vulmedium, sum(VULN.vulmedium) vulmedium, sum(mcrr."VulLow") mcrr_vullow, sum(VULN.vullow) vullow from rpt.V_CyberRisk_System_Summary mcrr JOIN CORE.VW_SYSTEMSUMMARY VULN on VULN.acronym = mcrr."System" where VULN.report_id = (select max(report_id) from core.report_ids where is_endofmonth = 1)
);


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