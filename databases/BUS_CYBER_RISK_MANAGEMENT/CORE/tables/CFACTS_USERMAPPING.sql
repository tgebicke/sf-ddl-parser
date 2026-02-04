create or replace TABLE CFACTS_USERMAPPING (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	ACRONYM VARCHAR(16777216),
	ROLE VARCHAR(16777216),
	SYSTEM_ID VARCHAR(16777216),
	USER_ID VARCHAR(16777216),
	primary key (ID)
)COMMENT='User role mapping for each system in CFACTS.\t'
;