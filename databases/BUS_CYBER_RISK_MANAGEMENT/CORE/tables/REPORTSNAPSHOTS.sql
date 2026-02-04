create or replace TABLE REPORTSNAPSHOTS (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	REPORT_ID NUMBER(38,0) NOT NULL,
	SNAPSHOT_ID NUMBER(38,0) NOT NULL,
	primary key (ID)
)COMMENT='Currently Empty Table. Based on definition: Table for Snapshot associated with Report ID\t'
;