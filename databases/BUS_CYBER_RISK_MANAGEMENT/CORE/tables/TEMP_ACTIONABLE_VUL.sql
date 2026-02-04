create or replace TABLE TEMP_ACTIONABLE_VUL (
	DW_ASSET_ID NUMBER(38,0),
	FIRST_SEEN TIMESTAMP_LTZ(9),
	LAST_SEEN TIMESTAMP_LTZ(9),
	PLUGIN_ID VARCHAR(16777216),
	RAW_TENABLE_VUL_ID NUMBER(38,0)
)COMMENT='Temporary (?)Table for Actionable Vuln. 5 columns identifying DW Asset ID and Vuln ID and plugin with dates for actionable Vuln\t'
;