create or replace TABLE SYSTEMSAWSACCOUNTS (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	AWS_ACCOUNTID VARCHAR(16777216) NOT NULL,
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	SYSTEM_ID VARCHAR(16777216) NOT NULL,
	primary key (ID)
)COMMENT='Information about Aws systems. Maps AWS account number to System ID\t'
;