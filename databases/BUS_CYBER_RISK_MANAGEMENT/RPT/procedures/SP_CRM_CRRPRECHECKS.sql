CREATE OR REPLACE PROCEDURE "SP_CRM_CRRPRECHECKS"()
RETURNS VARCHAR(16777216)
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
REPORT_ID number;
CurSnap number;
PreSnap number;
CurReportId number;
PreReportId number;
CurReportDate datetime;
PreReportDate datetime;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE(:Appl);

CREATE TEMPORARY TABLE temp_Snap (REPORTSNAPSHOTID number,
	DATACATEGORY varchar,
	REPORT_ID number,
	REPORT_DATE timestamp,
	IS_ENDOFMONTH boolean,
	SNAPSHOT_ID number,
	SNAPSHOT_DATE timestamp,
	MIN_DATE timestamp,
	MAX_DATE timestamp);
    
select * into temp_Snap from
CORE.VW_REPORTSNAPSHOTS where DATACATEGORY = ''CFACTS'' order by Report_ID desc; 

CurSnap := (select max(Snapshot_ID) from temp_Snap);
PreSnap := (select min(Snapshot_ID) from temp_Snap);

CurReportId := (select max(Snapshot_ID) from temp_Snap);
PreReportId := (select min(Snapshot_ID) from temp_Snap);

CurReportDate := (select Report_Date from temp_Snap where Snapshot_ID = CurSnap);
PreReportDate := (select Report_Date from temp_Snap where Snapshot_ID = PreSnap);

-- Checking acronyms
select Component_Acronym, Group_Acronym, Acronym, TLC_Phase, s.dateCreated into temp_Validate from Systems s
join Components c on c.COMPONENTNAME = s.COMPONENT_NAME
join Groups g on g.GROUPNAME = s.GROUP_NAME
where Acronym not in (select Systems from rpt.CRR_Component_Params) and TLC_Phase <> ''Retire'' and Component_Acronym <> ''Not specified'';

delete from temp_Validate where GroupAcronym not in (
Select distinct g.Groups from temp_Validate temp
join rpt.CRR_Component_Params C on C.Component = temp.ComponentAcronym
join rpt.CRR_Group_Params G on g.ReportName = C.ReportName 
) and ComponentAcronym not in (
Select distinct C.Component from temp_Validate temp
join rpt.CRR_Component_Params C on C.Component = temp.ComponentAcronym
join rpt.CRR_Group_All_Params G on g.ReportName = C.ReportName 
);

select * from temp_Validate;
drop table temp_Validate;

--Checking for component name changes 
select DISTINCT a.SystemID, a.Group_Acronym AS NEWGROUP,b.Group_Acronym  AS OLDGROUP
,A.TLC_Phase AS NEWPHASE,B.TLC_Phase AS OLDPHASE,A.Component_Acronym AS NEWCOMPONENT,B.Component_Acronym AS OLDCOMPONENT
from (SELECT * FROM CORE.SystemsHist WHERE SnapshotID=CurSnap) A
INNER JOIN (SELECT * FROM CORE.SystemsHist WHERE SnapshotID=PreSnap) B
ON a.SystemID = B.SystemID
AND A.Component_Acronym<>b.Component_Acronym;

--Checking for Group name changes 
select DISTINCT a.SystemID, a.Group_Acronym AS NEWGROUP,b.Group_Acronym  AS OLDGROUP
,A.TLC_Phase AS NEWPHASE,B.TLC_Phase AS OLDPHASE,A.Component_Acronym AS NEWCOMPONENT,B.Component_Acronym AS OLDCOMPONENT
from (SELECT * FROM CORE.SystemsHist WHERE SnapshotID=CurSnap) A
INNER JOIN (SELECT * FROM CORE.SystemsHist WHERE SnapshotID=PreSnap) B
ON a.SystemID = B.SystemID
WHERE  A.Group_Acronym<>B.Group_Acronym;

--Checking for XLC Phase changes 
select DISTINCT a.SystemID,a.Group_Acronym AS NEWGROUP,b.Group_Acronym  AS OLDGROUP
,A.TLC_Phase AS NEWPHASE,B.TLC_Phase AS OLDPHASE,A.Component_Acronym AS NEWCOMPONENT,B.Component_Acronym AS OLDCOMPONENT
from (SELECT * FROM CORE.SystemsHist WHERE SnapshotID=CurSnap) A
INNER JOIN (SELECT * FROM CORE.SystemsHist WHERE SnapshotID=PreSnap) B
ON a.SystemID = B.SystemID
WHERE  A.TLC_Phase<>B.TLC_Phase;

-- Removed Systems 
select  Acronym from V_SystemsSummary where ReportID=PreReportId 
except
select  Acronym from V_SystemsSummary where ReportID=CurReportId;

-- Added Systems 
select  Acronym from V_SystemsSummary where ReportID=CurReportId 
except
select  Acronym from V_SystemsSummary where ReportID=PreReportId;

/*DW Data file egenrated is checked for counts and compared with counts below from the views and they have to match*/
select count(*), FISMAseverity from rpt.V_CyberRisk_VUL_Detail  group by FISMAseverity;
select count(*), FISMAseverity from rpt.V_VulCur group by FISMAseverity;

Select top 3 * from SnapShotIDs order by SnapshotDate desc;
Select ''System'', max(SnapshotID) SnapshotID, Count(SnapshotID) as Ssystem FROM CORE.SystemsHist union all
Select ''CAA'', max(SnapshotID) SnapshotID, Count(SnapshotID) as CAAT from CAATHist union all
Select ''POAM'', max(SnapshotID) SnapshotID, Count(SnapshotID) as POAM from POAMHist union all
Select ''PIA'', max(SnapshotID) SnapshotID, Count(SnapshotID) as PIA from PIAHist union all
Select ''Milestone'', max(SnapshotID) SnapshotID, Count(SnapshotID) as MS from MilestoneHist ;

drop table temp_Snap;
  
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