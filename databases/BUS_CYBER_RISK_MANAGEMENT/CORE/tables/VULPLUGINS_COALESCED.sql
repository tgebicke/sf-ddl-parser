create or replace TABLE VULPLUGINS_COALESCED (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	DW_VUL_ID NUMBER(38,0),
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	PLUGIN_ID VARCHAR(16777216),
	PLUGINIDLINK VARCHAR(16777216),
	primary key (ID)
)COMMENT='Currently Empty Table. Based on definition: Coalesced (fewer column) table of vuln and definition links\t'
;