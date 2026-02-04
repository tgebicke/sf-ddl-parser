create or replace TABLE INVALIDUIDS (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	DATASOURCE VARCHAR(16777216),
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	INVALIDUID VARCHAR(16777216),
	primary key (ID)
)COMMENT='List of IDs previously determined to be invalid and are used to generate error messages for asset records.\t'
;