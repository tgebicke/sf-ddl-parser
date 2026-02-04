create or replace TABLE CRR_GROUP_ALL_PARAMS (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	GROUPS VARCHAR(16777216),
	REPORTNAME VARCHAR(16777216),
	primary key (ID)
)COMMENT='Not using in tableau'
;