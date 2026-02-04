create or replace TABLE PII_CATEGORY (
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	LEVEL VARCHAR(16777216),
	LEVEL_NUM NUMBER(38,0),
	PII_CATEGORY VARCHAR(16777216) NOT NULL,
	primary key (PII_CATEGORY)
)COMMENT='Table of Personal Identifiable Information (PII) Category. Maps PII level number to PII category \t'
;