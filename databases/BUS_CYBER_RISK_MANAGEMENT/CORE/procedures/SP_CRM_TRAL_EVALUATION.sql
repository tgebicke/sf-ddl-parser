CREATE OR REPLACE PROCEDURE "SP_CRM_TRAL_EVALUATION"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Evaluate systems to determine if OA metrics passed such that a TRigger Accountability Log (TRAL) can be generated.'
EXECUTE AS OWNER
AS '

DECLARE
Appl varchar := ''SP_CRM_TRAL_EVALUATION'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
TodaysDate date := CURRENT_DATE();
BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

-- TEMPORARY -  Need to ensure same System/Metric is unique  (Only one dateIdentified)
--TRUNCATE TABLE CORE.TRAL_Log;

/*
Trigger Description 	RL1	RL2	RL3
Failed to complete Pen Test within the specified frequency.	N/A	2	2
Failed to complete ACT within the specified frequency.	1	2	3
System exceeded specified threshold for Vuln Risk Tolerance. 	2	2	2
System exceeded the specified threshold for Resiliency Score. 	2	2	3
System exceeded threshold for Asset Risk Tolerance. 	1	1	2
			
Low Severity: 	1		
Moderate Severity:	2		
High Severity:	3		

ID	MetricName
1	Last Pen Test
2	Last ACT
3	Vuln Risk Tolerance
4	Resiliency Score
5	Asset Risk Tolerance
*/

-- Create new TRAL_Log if SystemID/MetricID does not already exist
INSERT INTO CORE.TRAL_Log
           (dateIdentified
           ,SYSTEM_ID 
           ,TRAL_METRIC_ID 
		   ,InitialScore
           ,INSERT_DATE)
select 
:TodaysDate
,s.SYSTEM_ID
,TM.TRAL_METRIC_ID
,DATEDIFF(d,s.Last_Pentest_Date,CURRENT_DATE()) 
,:TodaysDate
FROM CORE.Systems s
JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
where s.Is_PhantomSystem = 0 
and tm.MetricName = ''Last Pen Test''
and (s.Last_Pentest_Date IS NULL or DATEDIFF(d,s.Last_Pentest_Date,CURRENT_DATE()) > trsl.Threshold) 
and l.ID IS NULL;

--Msg := ''Last Pen Test INSERT complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

-- INTENT OF THIS CODE IS TO CREATE A NEW (dateIdentified) if a prior issue had been mitigated
--or (s.Last_Pentest_Date IS NOT NULL and l.dateMitigated IS NOT NULL and s.Last_Pentest_Date > l.dateMitigated)

-- Create new TRAL_Log if SystemID/MetricID does not already exist
INSERT INTO CORE.TRAL_Log
           (dateIdentified
           ,SYSTEM_ID 
           ,TRAL_METRIC_ID 
		   ,InitialScore
           ,INSERT_DATE)
select 
:TodaysDate
,s.SYSTEM_ID
,TM.TRAL_METRIC_ID
,DATEDIFF(d,s.Last_ACT_Date,CURRENT_DATE()) 
,:TodaysDate
FROM CORE.Systems s
JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
where s.Is_PhantomSystem = 0 
and tm.MetricName = ''Last ACT''
and (s.Last_ACT_Date IS NULL or DATEDIFF(d,s.Last_ACT_Date,CURRENT_DATE()) > trsl.Threshold)
and l.ID IS NULL;

--Msg := ''Last ACT INSERT complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

-- Create new TRAL_Log if SystemID/MetricID does not already exist
INSERT INTO CORE.TRAL_Log
           (dateIdentified
           ,SYSTEM_ID 
           ,TRAL_METRIC_ID 
		   ,InitialScore
           ,INSERT_DATE)
select 
:TodaysDate
,s.SYSTEM_ID
,TM.TRAL_METRIC_ID
,ss.VulnRiskTolerance
,:TodaysDate
FROM CORE.Systems s
JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
JOIN CORE.SystemSummary ss on SS.SYSTEM_ID  = s.SYSTEM_ID
	and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary)
LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
where s.Is_PhantomSystem = 0 
and tm.MetricName = ''Vuln Risk Tolerance''
and ss.VulnRiskTolerance > trsl.Threshold
and l.ID IS NULL;

--Msg := ''Vuln Risk Tolerance INSERT complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

-- Create new TRAL_Log if SystemID/MetricID does not already exist
INSERT INTO CORE.TRAL_Log
           (dateIdentified
           ,SYSTEM_ID 
           ,TRAL_METRIC_ID 
		   ,InitialScore
           ,INSERT_DATE)
select 
:TodaysDate
,s.SYSTEM_ID
,TM.TRAL_METRIC_ID
,ss.ResiliencyScore 
,:TodaysDate
FROM CORE.Systems s
JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
JOIN CORE.SystemSummary ss on SS.SYSTEM_ID  = s.SYSTEM_ID
	and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary)
LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
where s.Is_PhantomSystem = 0 
and tm.MetricName = ''Resiliency Score''
and ss.ResiliencyScore > trsl.Threshold
and l.ID IS NULL;

--Msg := ''Resiliency Score INSERT complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

-- Create new TRAL_Log if SystemID/MetricID does not already exist
INSERT INTO CORE.TRAL_Log
           (dateIdentified
           ,SYSTEM_ID 
           ,TRAL_METRIC_ID 
		   ,InitialScore
           ,INSERT_DATE)
select 
:TodaysDate
,s.SYSTEM_ID
,TM.TRAL_METRIC_ID
,ABS(ss.AssetRiskTolerance)
,:TodaysDate
FROM CORE.Systems s
JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
JOIN CORE.SystemSummary ss on SS.SYSTEM_ID  = s.SYSTEM_ID
	and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary)
LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
where s.Is_PhantomSystem = 0 
and tm.MetricName = ''Asset Risk Tolerance''
and ABS(ss.AssetRiskTolerance) > trsl.Threshold
and l.ID IS NULL;

--Msg := ''Asset Risk Tolerance INSERT complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

--
-- Check for mitigation
--
UPDATE CORE.TRAL_LOG upd -- 240509 CR893 EBF
set dateMitigated = CURRENT_DATE()
,SubsequentScore = t.subsequentScore
,DATEMODIFIED = CURRENT_TIMESTAMP() -- 240509 CR893 EBF
FROM CORE.TRAL_Log tl
JOIN (select s.SYSTEM_ID,TM.TRAL_METRIC_ID,DATEDIFF(d,coalesce(s.Last_Pentest_Date,CAST(''01/01/1900'' as datetime)),CURRENT_DATE()) as subsequentScore
	FROM CORE.Systems s
	JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
	JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
	JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
	JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
	where s.Is_PhantomSystem = 0 
	and tm.MetricName = ''Last Pen Test''
	and (l.dateMitigated IS NULL or (s.Last_Pentest_Date IS NOT NULL and s.Last_Pentest_Date > l.dateMitigated))
	and DATEDIFF(d,coalesce(s.Last_Pentest_Date,CAST(''01/01/1900'' as datetime)),CURRENT_DATE()) <= trsl.Threshold
	) t on t.SYSTEM_ID = tL.SYSTEM_ID and t.TRAL_METRIC_ID = TL.TRAL_METRIC_ID
where upd.SYSTEM_ID = tL.SYSTEM_ID and upd.TRAL_METRIC_ID = TL.TRAL_METRIC_ID; -- 240509 CR893 EBF

--Msg := ''Last Pen Test UPDATE complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

UPDATE CORE.TRAL_LOG upd -- 240509 CR893 EBF
set dateMitigated = CURRENT_DATE()
,SubsequentScore = t.subsequentScore
,DATEMODIFIED = CURRENT_TIMESTAMP() -- 240509 CR893 EBF
FROM CORE.TRAL_Log tl
JOIN (select s.SYSTEM_ID,TM.TRAL_METRIC_ID,DATEDIFF(d,coalesce(s.Last_ACT_Date,CAST(''01/01/1900'' as datetime)),CURRENT_DATE()) as subsequentScore
	FROM CORE.Systems s
	JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
	JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
	JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
	JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
	where s.Is_PhantomSystem = 0 
	and tm.MetricName = ''Last ACT''
	and (l.dateMitigated IS NULL or (s.Last_ACT_Date IS NOT NULL and s.Last_ACT_Date > l.dateMitigated))
	and DATEDIFF(d,coalesce(s.Last_ACT_Date,CAST(''01/01/1900'' as datetime)),CURRENT_DATE()) <= trsl.Threshold
	) t on t.SYSTEM_ID = tL.SYSTEM_ID and t.TRAL_METRIC_ID = TL.TRAL_METRIC_ID
where upd.SYSTEM_ID = tL.SYSTEM_ID and upd.TRAL_METRIC_ID = TL.TRAL_METRIC_ID; -- 240509 CR893 EBF

--Msg := ''Last ACT UPDATE complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

UPDATE CORE.TRAL_LOG upd -- 240509 CR893 EBF
set dateMitigated = CURRENT_DATE()
,SubsequentScore = t.subsequentScore
,DATEMODIFIED = CURRENT_TIMESTAMP() -- 240509 CR893 EBF
FROM CORE.TRAL_Log tl
JOIN (select s.SYSTEM_ID,TM.TRAL_METRIC_ID,ss.VulnRiskTolerance as subsequentScore
	FROM CORE.Systems s
	JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
	JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
	JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
	JOIN CORE.SystemSummary ss on SS.SYSTEM_ID  = s.SYSTEM_ID
		and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary)
	LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
	where s.Is_PhantomSystem = 0 
	and tm.MetricName = ''Vuln Risk Tolerance''
	and l.dateMitigated IS NULL
	and ss.VulnRiskTolerance <= trsl.Threshold
	) t on t.SYSTEM_ID = tL.SYSTEM_ID and t.TRAL_METRIC_ID = TL.TRAL_METRIC_ID
where upd.SYSTEM_ID = tL.SYSTEM_ID and upd.TRAL_METRIC_ID = TL.TRAL_METRIC_ID; -- 240509 CR893 EBF

--Msg := ''Vuln Risk Tolerance UPDATE complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

UPDATE CORE.TRAL_LOG upd -- 240509 CR893 EBF
set dateMitigated = CURRENT_DATE()
,SubsequentScore = t.subsequentScore
,DATEMODIFIED = CURRENT_TIMESTAMP() -- 240509 CR893 EBF
FROM CORE.TRAL_Log tl
JOIN (select s.SYSTEM_ID,TM.TRAL_METRIC_ID,ss.ResiliencyScore as subsequentScore
	FROM CORE.Systems s
	JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
	JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
	JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
	JOIN CORE.SystemSummary ss on SS.SYSTEM_ID  = s.SYSTEM_ID
		and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary)
	LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
	where s.Is_PhantomSystem = 0 
	and tm.MetricName = ''Resiliency Score''
	and l.dateMitigated IS NULL
	and ss.ResiliencyScore <= trsl.Threshold
	) t on t.SYSTEM_ID = tL.SYSTEM_ID and t.TRAL_METRIC_ID = TL.TRAL_METRIC_ID
where upd.SYSTEM_ID = tL.SYSTEM_ID and upd.TRAL_METRIC_ID = TL.TRAL_METRIC_ID; -- 240509 CR893 EBF

--Msg := ''Resiliency Score UPDATE complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

UPDATE CORE.TRAL_LOG upd -- 240509 CR893 EBF
set dateMitigated = CURRENT_DATE()
,SubsequentScore = t.subsequentScore
,DATEMODIFIED = CURRENT_TIMESTAMP() -- 240509 CR893 EBF
FROM CORE.TRAL_Log tl
JOIN (select s.SYSTEM_ID,TM.TRAL_METRIC_ID,ABS(ss.AssetRiskTolerance) as subsequentScore
	FROM CORE.Systems s
	JOIN CORE.SystemRiskCategory src on src.SYSTEMRISKCATEGORY_ID = s.OATO_Category
	JOIN CORE.TRAL_RiskSeverityLevel trsl on TRSL.SYSTEMRISKCATEGORY_ID = src.SYSTEMRISKCATEGORY_ID
	JOIN CORE.TRAL_Metric tm on TM.TRAL_METRIC_ID = TRSL.TRAL_METRIC_ID
	JOIN CORE.SystemSummary ss on SS.SYSTEM_ID  = s.SYSTEM_ID
		and ss.REPORT_ID = (select max(REPORT_ID) FROM CORE.SystemSummary)
	LEFT OUTER JOIN CORE.TRAL_Log l on L.SYSTEM_ID = s.SYSTEM_ID and L.TRAL_METRIC_ID = TM.TRAL_METRIC_ID
	where s.Is_PhantomSystem = 0 
	and tm.MetricName = ''Asset Risk Tolerance''
	and l.dateMitigated IS NULL
	and ABS(ss.AssetRiskTolerance) <= trsl.Threshold
	) t on t.SYSTEM_ID = tL.SYSTEM_ID and t.TRAL_METRIC_ID = TL.TRAL_METRIC_ID
where upd.SYSTEM_ID = tL.SYSTEM_ID and upd.TRAL_METRIC_ID = TL.TRAL_METRIC_ID; -- 240509 CR893 EBF

--Msg := ''Asset Risk Tolerance UPDATE complete'';
--CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl, :Msg);

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