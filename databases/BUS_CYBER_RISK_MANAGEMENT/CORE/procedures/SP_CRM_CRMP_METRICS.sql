CREATE OR REPLACE PROCEDURE "SP_CRM_CRMP_METRICS"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Write most current vulnerability counts to CORE.CRMP_METRICS table'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_CRMP_METRICS'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
NotSpecified varchar := ''Not specified'';
BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);


Truncate table CORE.CRMP_Metrics; 
------Datacenter
--------------------------------------------Critical/System-------------------------------------------------------------
INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''All'' as MitigationStatus
,0 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) IN (''fixed'',''open'',''reopened'') 
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery > 30
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,0 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery <= 30
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''All'' as MitigationStatus
,1 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) IN (''open'',''reopened'') 
and vm.Is_Legacy = 1 
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,1 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 1 
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

----------------------------------------------High/System-------------------------------------------------------------
INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''All'' as MitigationStatus
,0 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) IN (''fixed'',''open'',''reopened'') 
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery > 60
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,0 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery <= 60
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  select ''High'' as FISMAseverity 
,''All'' as MitigationStatus
,1 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) IN (''open'',''reopened'') 
and vm.Is_Legacy = 1 
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,1 as Is_Legacy
,''System'' as LevelType
,t.Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.Acronym, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 1 
GROUP BY sf.ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Acronym;

------Component
--------------------------------------------Critical/Component-------------------------------------------------------------
INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''All'' as MitigationStatus
,0 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) IN (''fixed'',''open'',''reopened'') 
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery > 30
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,0 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery <= 30
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''All'' as MitigationStatus
,1 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) IN (''open'',''reopened'') 
and vm.Is_Legacy = 1 
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,1 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 1 
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

----------------------------------------------High/Component-------------------------------------------------------------
INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''All'' as MitigationStatus
,0 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) IN (''fixed'',''open'',''reopened'') 
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery > 60
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,0 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery <= 60
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''All'' as MitigationStatus
,1 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) IN (''open'',''reopened'') 
and vm.Is_Legacy = 1 
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,1 as Is_Legacy
,''Component'' as LevelType
,t.Component_Acronym as LevelName
,count(1) as Total 
from (
SELECT sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 1 
GROUP BY sf.COMPONENT_ACRONYM, vm.DW_ASSET_ID, vm.CVE
) t
GROUP BY t.Component_Acronym;

------Group
--------------------------------------------Critical/Group-------------------------------------------------------------
INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''All'' as MitigationStatus
,0 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) IN (''fixed'',''open'',''reopened'') 
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery > 30
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,0 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery <= 30
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''All'' as MitigationStatus
,1 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) IN (''open'',''reopened'') 
and vm.Is_Legacy = 1 
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''Critical'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,1 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''critical'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 1 
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

----------------------------------------------High/Group-------------------------------------------------------------
INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''All'' as MitigationStatus
,0 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) IN (''fixed'',''open'',''reopened'') 
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery > 60
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,0 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 0 and vm.DaysSinceDiscovery <= 60
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''All'' as MitigationStatus
,1 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) IN (''open'',''reopened'') 
and vm.Is_Legacy = 1 
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

INSERT into CORE.CRMP_METRICS (FISMASEVERITY,MITIGATIONSTATUS,IS_LEGACY,LEVELTYPE,LEVELNAME,TOTAL)  
select ''High'' as FISMAseverity 
,''Fixed'' as MitigationStatus
,1 as Is_Legacy
,''Group'' as LevelType
,coalesce(t.Group_Acronym,:NotSpecified) as LevelName
,count(1) as Total 
from (
SELECT sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
FROM CORE.VW_VULMASTER vm
INNER JOIN CORE.VW_SYSTEMS sf ON sf.SYSTEM_ID = vm.DATACENTER_ID and sf.Is_OperationalSystem = 1
WHERE LOWER(vm.FISMAseverity)=''high'' and LOWER(vm.MitigationStatus) = ''fixed''
and vm.Is_Legacy = 1 
GROUP BY sf.Group_Acronym,VM.DW_ASSET_ID,vm.CVE
) t
GROUP BY t.Group_Acronym;

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