create or replace view "V_ISPG-DIR_ALLOCATED CONTROLS"(
	CONTROL_NUMBER,
	CONTROL_NAME
) COMMENT='Allocated Controls related data'
 as
SELECT DISTINCT
 accs.Control_Number
,accs.Control_Name
FROM CORE.VW_ALLOCATEDCONTROL accs;