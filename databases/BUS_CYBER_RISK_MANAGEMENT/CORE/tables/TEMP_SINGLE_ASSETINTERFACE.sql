create or replace TABLE TEMP_SINGLE_ASSETINTERFACE (
	ID NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 order,
	DW_ASSET_ID NUMBER(38,0),
	FQDN VARCHAR(16777216),
	HOSTNAME VARCHAR(16777216),
	IPV4 VARCHAR(16777216),
	IPV6 VARCHAR(16777216),
	MACADDRESS VARCHAR(16777216),
	NETBIOSNAME VARCHAR(16777216),
	REPORT_ID NUMBER(38,0),
	primary key (ID)
)COMMENT='Temporary Table for information on HWAM assets. Maps DW Asset ID to the asset information (FQDN, hostname, ipv4 etc.)\t'
;