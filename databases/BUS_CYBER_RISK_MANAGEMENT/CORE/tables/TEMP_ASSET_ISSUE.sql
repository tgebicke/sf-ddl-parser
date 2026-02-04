create or replace TABLE TEMP_ASSET_ISSUE (
	DW_ASSET_ID NUMBER(38,0),
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	ISSUE_MSG VARCHAR(16777216)
)COMMENT='Temporary Table for Asset issues. e.g. duplicates\t'
;