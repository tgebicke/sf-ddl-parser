CREATE OR REPLACE PROCEDURE "SP_CRM_CRRPRECHECKS_NEW"()
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

CREATE TEMPORARY TABLE temp_Snap (
	REPORT_ID number,
	REPORT_DATE timestamp,
	IS_ENDOFMONTH boolean
	);
    
INSERT into temp_Snap SELECT REPORT_ID, REPORT_DATE, IS_ENDOFMONTH FROM core.report_ids;

CurSnap := (select max(Report_ID) from temp_Snap);
PreSnap := (select max(Report_ID) from temp_Snap where is_endofmonth = 1);

CurReportId := (select max(Report_ID) from temp_Snap);
PreReportId := (select max(Report_ID) from temp_Snap where is_endofmonth = 1);

-- Checking acronyms
CREATE TEMPORARY TABLE temp_Validate (
	COMPONENT_ACRONYM varchar,
	GROUP_ACRONYM varchar,
	ACRONYM varchar,
    TLC_PHASE varchar,
    FIRST_PUBLISHED_DATE Date
	);
INSERT INTO temp_Validate select Component_Acronym, Group_Acronym, Acronym, TLC_Phase, first_published_date from CORE.SYSTEMS s
where Acronym not in (select Systems from rpt.CRR_Component_Params) and TLC_Phase <> ''Retire'' and Component_Acronym <> ''Not specified'';

delete from temp_Validate where Group_Acronym not in (
Select distinct c.groups from temp_Validate temp
join rpt.CRR_Component_Params C on C.Component = temp.Component_Acronym
) and Component_Acronym not in (
Select distinct C.Component from temp_Validate temp
join rpt.CRR_Component_Params C on C.Component = temp.Component_Acronym
);

select * from temp_Validate;
drop table temp_Validate;

--Checking for component name changes 
res := (select DISTINCT a.System_ID, a.Group_Acronym AS NEWGROUP,b.Group_Acronym  AS OLDGROUP
,A.TLC_Phase AS NEWPHASE,B.TLC_Phase AS OLDPHASE,A.Component_Acronym AS NEWCOMPONENT,B.Component_Acronym AS OLDCOMPONENT
from (SELECT * FROM CORE.SystemsHist WHERE Report_ID=(select max(Report_ID) from temp_Snap)) A
INNER JOIN (SELECT * FROM CORE.SystemsHist WHERE Report_ID=(select max(Report_ID) from temp_Snap where is_endofmonth = 1)) B
ON a.System_ID = B.System_ID
AND A.Component_Acronym<>b.Component_Acronym);

--Checking for Group name changes 
res1 := (select DISTINCT a.System_ID, a.Group_Acronym AS NEWGROUP,b.Group_Acronym  AS OLDGROUP
,A.TLC_Phase AS NEWPHASE,B.TLC_Phase AS OLDPHASE,A.Component_Acronym AS NEWCOMPONENT,B.Component_Acronym AS OLDCOMPONENT
from (SELECT * FROM CORE.SystemsHist WHERE Report_ID=(select max(Report_ID) from temp_Snap)) A
INNER JOIN (SELECT * FROM CORE.SystemsHist WHERE Report_ID=(select max(Report_ID) from temp_Snap where is_endofmonth = 1)) B
ON a.System_ID = B.System_ID
WHERE  A.Group_Acronym<>B.Group_Acronym);

--Checking for XLC Phase changes 
select DISTINCT a.System_ID,a.Group_Acronym AS NEWGROUP,b.Group_Acronym  AS OLDGROUP
,A.TLC_Phase AS NEWPHASE,B.TLC_Phase AS OLDPHASE,A.Component_Acronym AS NEWCOMPONENT,B.Component_Acronym AS OLDCOMPONENT
from (SELECT * FROM CORE.SystemsHist WHERE Report_ID=(select max(Report_ID) from temp_Snap)) A
INNER JOIN (SELECT * FROM CORE.SystemsHist WHERE Report_ID=(select max(Report_ID) from temp_Snap where is_endofmonth = 1)) B
ON a.System_ID = B.System_ID
WHERE  A.TLC_Phase<>B.TLC_Phase;

-- Removed Systems 
select  Acronym from CORE.VW_SYSTEMSUMMARY where REPORT_ID=(select max(Report_ID) from temp_Snap where is_endofmonth = 1) 
except
select  Acronym from CORE.VW_SYSTEMSUMMARY where REPORT_ID=(select max(Report_ID) from temp_Snap);

-- Added Systems 
select  Acronym from CORE.VW_SYSTEMSUMMARY where REPORT_ID=(select max(Report_ID) from temp_Snap) 
except
select  Acronym from CORE.VW_SYSTEMSUMMARY where REPORT_ID=(select max(Report_ID) from temp_Snap where is_endofmonth = 1);

drop table temp_Snap;
  
CALL CORE.SP_CRM_END_PROCEDURE(:Appl);

RETURN TABLE(res);
RETURN TABLE(res1);

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