create or replace TABLE TEMP_BOD (
	CVE VARCHAR(16777216),
	DATEADDED DATE,
	VULNERABILITYNAME VARCHAR(16777216)
)COMMENT='Temporary Table for ingestion of BOD template file and generation of BOD report'
;