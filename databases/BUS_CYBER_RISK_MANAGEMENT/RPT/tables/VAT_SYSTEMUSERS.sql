create or replace TABLE VAT_SYSTEMUSERS (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	SYSTEM_ID VARCHAR(16777216) NOT NULL,
	USERID VARCHAR(16777216),
	primary key (ID)
)COMMENT='List of VAT provided Data Center users'
;