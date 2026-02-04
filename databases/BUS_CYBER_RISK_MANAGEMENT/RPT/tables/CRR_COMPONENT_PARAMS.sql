create or replace TABLE CRR_COMPONENT_PARAMS (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	COMPONENT VARCHAR(16777216),
	DATECREATED TIMESTAMP_LTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	GROUPS VARCHAR(16777216),
	REPORTNAME VARCHAR(16777216),
	SYSTEMS VARCHAR(16777216),
	primary key (ID)
)COMMENT='Look up table to get report name based on acronym and component acronym for MCRR report'
;