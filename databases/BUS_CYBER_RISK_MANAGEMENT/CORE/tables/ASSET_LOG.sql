create or replace TABLE ASSET_LOG (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	DW_ASSET_ID NUMBER(38,0) NOT NULL,
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	COMMENTS VARCHAR(16777216) NOT NULL,
	primary key (ID)
)COMMENT='ASSET (MDR) log for recording deletions, system_ID, other.\t'
;