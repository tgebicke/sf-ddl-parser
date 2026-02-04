create or replace view VW_PII_SYSTEM_PII_TYPES(
	SYSTEMID,
	AUTHORIZATION_PACKAGE,
	PII_TYPE,
	RECORD_DATE,
	RECORD_SOURCE_DATA,
	PII_CATEGORY,
	LEVEL,
	LEVEL_NUM,
	TYPE_DEFINITION,
	HHS_POLICY_DESCRIPTION
) COMMENT='Shows the type of PII associated with a system.'
 as
SELECT st.SYSTEM_ID as SystemID
,s.Authorization_Package
,dt.PII_Type
,st.record_date
,st.record_source_data
,dc.PII_Category
,dc.Level
,dc.Level_Num
,dt.Type_Definition
,dt.HHS_Policy_Description
FROM CORE.PII_System_PII_Types st
JOIN CORE.PII_DataType dt on dt.PII_TYPE = st.PII_TYPE
JOIN CORE.PII_Category dc on dc.PII_CATEGORY = dt.PII_Category
JOIN CORE.VW_Systems s on s.SYSTEM_ID = st.SYSTEM_ID;