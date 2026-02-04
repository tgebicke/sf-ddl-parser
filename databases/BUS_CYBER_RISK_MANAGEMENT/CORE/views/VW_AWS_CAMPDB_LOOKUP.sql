create or replace view VW_AWS_CAMPDB_LOOKUP(
	DATE,
	DATA_CENTER,
	FISMA,
	SYSTEM_ACRONYM,
	ACCOUNT_NUMBER,
	VERIFIED_DATA_CENTER,
	VERIFIED_FISMA,
	VERIFIED_SYSTEM_ACRONYM,
	VERIFIED_COMMONNAME,
	DATACENTER_ID,
	SYSTEM_ID
) COMMENT='CRITICAL; Replacement for SEC_VW_FISMA_LOOKUPS which comes from CAMP DB. Validates/Resolves SYSTEM_ACRONYM if common-name\t'
 as
SELECT 
--
-- CAMP DB (source) can have errors due to case.
-- We use UPPER function to improve the odds of matching DATACENTER_ID and SYSTEM_ID.
--
flu.DATE
,flu.DATA_CENTER
,flu.FISMA
,flu.SYSTEM_ACRONYM
,flu.ACCOUNT_NUMBER
,dc.SYSTEM_ID as Verified_DATA_CENTER
,s.SYSTEM_ID as Verified_FISMA
,sa.ACRONYM as Verified_SYSTEM_ACRONYM
,sc.ACRONYM as Verified_COMMONNAME
,coalesce(dc.SYSTEM_ID,'CAMPDB has invalid DATA_CENTER') as DATACENTER_ID -- This is the fieldname used throughout SDW
,coalesce(s.SYSTEM_ID,sa.SYSTEM_ID,sc.SYSTEM_ID,'Cant determine CAMPDB SYSTEM_ID') as SYSTEM_ID -- This is the fieldname used throughout SDW
FROM REF_LOOKUPS.SHARED.SEC_VW_FISMA_LOOKUPS flu
LEFT OUTER JOIN CORE.VW_SYSTEMS dc on upper(dc.SYSTEM_ID) = upper(flu.DATA_CENTER)
LEFT OUTER JOIN CORE.VW_SYSTEMS s on upper(s.SYSTEM_ID) = upper(flu.FISMA)
LEFT OUTER JOIN CORE.VW_SYSTEMS sa on upper(sa.ACRONYM) = upper(flu.SYSTEM_ACRONYM)
LEFT OUTER JOIN CORE.VW_SYSTEMS sc on upper(sc.COMMONNAME) = upper(flu.SYSTEM_ACRONYM)
;