create or replace TABLE CORECONTROLS (
	CONTROL VARCHAR(16777216) NOT NULL,
	INSERT_DATE TIMESTAMP_LTZ(9) NOT NULL,
	primary key (CONTROL)
)COMMENT='Core system security controls (e.g. NIST 800-53)\t'
;