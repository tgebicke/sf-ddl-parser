create or replace TABLE SYSTEM_COMMONNAME (
	COMMONNAME VARCHAR(16777216),
	SYSTEM_ID VARCHAR(16777216)
)COMMENT='System Common Name Lookup Table. This is not an official CFACTS System Acronym but is used by various teams. Maps the System Common Name based on System ID\t'
;