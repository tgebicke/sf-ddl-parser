create or replace view VW_CEDE_SYSTEM_PII_LEVEL(
	AUTHORIZATION_PACKAGE,
	SYS_PII_LEVEL
) COMMENT='Contains System information, PII level and aver all prioritization level'
 as
SELECT Authorization_Package,sys_pii_level
FROM (SELECT s.Authorization_Package
    ,CASE 
	WHEN MIN(dc.Level_Num) OVER(PARTITION BY Authorization_Package)= 1 THEN 'Sensitive PII'
	WHEN MIN(dc.Level_Num) OVER(PARTITION BY Authorization_Package)= 2 THEN 'Context-Combine PII'
	WHEN MIN(dc.Level_Num) OVER(PARTITION BY Authorization_Package)= 3 THEN 'Non-sensitive PII'
	WHEN MIN(dc.Level_Num) OVER(PARTITION BY Authorization_Package)= 4 THEN 'No PII'
	ELSE 'Undetermined'
	END as sys_pii_level
FROM CORE.VW_SYSTEMS s
JOIN CORE.PII_SYSTEM_PII_TYPES st on st.SYSTEM_ID = s.SYSTEM_ID
JOIN CORE.PII_DATATYPE dt on dt.PII_TYPE = st.PII_TYPE
JOIN CORE.PII_CATEGORY dc on dc.PII_CATEGORY = dt.PII_CATEGORY) t  
--  FROM CEDE.VW_CEDE_Privacy_Impact_Assessment_PIA) a
GROUP by t.Authorization_Package,t.sys_pii_level
;