create or replace view VW_CEDE_PRIORITIZATION_SYSTEM_CRITICALITY(
	AUTHORIZATION_PACKAGE,
	SYSTEM_CRITICALITY,
	MAX,
	MIN,
	NORM_SYSTEM_CRITICALITY
) COMMENT='Contains Systems Criticality  related information at org hierarchy level'
 as
/* About the view: Criticality is determined based on whether a system is designated as HVA and its MEF alignments.  
HVA systems are top priority, though should be closely aligned with MEFs.  
The Expected results range 0-5.5; Higher number = higher system criticality 
The scoring sums the following for each system: HVA= True 4, 1 MEF=1, 2 MEFs=1.5
The field 'norm_system_criticality' normalizes the scores across all systems from 0-1.*/
SELECT a.AUTHORIZATION_PACKAGE,
(a.hva_factor + a.mef_factor) as system_criticality,
MAX(a.hva_factor + a.mef_factor) OVER() as max,
MIN(a.hva_factor + a.mef_factor) OVER() as min
--,ROUND(((a.hva_factor + a.mef_factor)-(MIN(a.hva_factor + a.mef_factor) OVER()))/((MAX(a.hva_factor + a.mef_factor) OVER())-(MIN(a.hva_factor + a.mef_factor) OVER())),3) as norm_system_criticality
,ROUND(DIV0(((a.hva_factor + a.mef_factor)-(MIN(a.hva_factor + a.mef_factor) OVER())), ((MAX(a.hva_factor + a.mef_factor) OVER())-(MIN(a.hva_factor + a.mef_factor)) OVER())),3) as norm_system_criticality
FROM (SELECT AUTHORIZATION_PACKAGE
      ,CASE WHEN ISCURRENTYEARHVALIST='Yes' then 4 else 0 end as hva_factor
      ,CASE when len(MISSIONESSENTIALFUNCTIONS_MEFS) = 365 then 1.5 
	  when len(MISSIONESSENTIALFUNCTIONS_MEFS) = 174 then 1 
	  when len(MISSIONESSENTIALFUNCTIONS_MEFS) = 190 then 1 
	  else 0 end AS mef_factor
  FROM CEDE.VW_CEDE_AUTHORIZATION_PACKAGES) a;