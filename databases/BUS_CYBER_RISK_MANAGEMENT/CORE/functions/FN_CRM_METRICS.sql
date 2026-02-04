CREATE OR REPLACE FUNCTION "FN_CRM_METRICS"("P_Level" VARCHAR(16777216), "P_FISMAseverity" VARCHAR(16777216), "P_Is_Legacy" BOOLEAN)
RETURNS TABLE ("LEVELNAME" VARCHAR(16777216), "NOTCLOSEDTIMELY" NUMBER(38,0), "TOTALCLOSED" NUMBER(38,0), "PERCENTAGECLOSED" NUMBER(5,2))
LANGUAGE SQL
COMMENT='Returns Metrics Table'
AS '
    WITH
    o as (
        SELECT TOP 1 LevelName, Total
        from CORE.CRMP_Metrics 
        where LevelType=COALESCE(P_Level,''Datacenter'') and FISMAseverity=COALESCE(P_FISMAseverity,''Critical'') and MitigationStatus=''All'' and Is_Legacy=P_Is_Legacy 
    ),
    f as (
        SELECT TOP 1 LevelName, Total
        from CORE.CRMP_Metrics 
        where LevelType=COALESCE(P_Level,''Datacenter'') and FISMAseverity=COALESCE(P_FISMAseverity,''Critical'') and MitigationStatus=''Fixed'' and Is_Legacy=P_Is_Legacy 
    )
    select 
     COALESCE(o.LevelName,f.LevelName) LevelName
    ,COALESCE(o.Total,0) as NotClosedTimely
    ,COALESCE(f.Total,0) TotalClosed
    ,cast(COALESCE(f.Total,0)*100.00/(COALESCE(o.Total,0)+COALESCE(f.Total,0)) as decimal(5,2)) as PercentageClosed
    from o full join f on o.LevelName=f.LevelName      
';