create or replace task TSK_CRM_AWS_HWAM
	warehouse=CYBER_RISK_MANAGEMENT_03_WH
	schedule='using cron 15 4 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Pull AWS HWAM and process into CRM database'
	as CALL CORE.SP_CRM_AWS_HWAM();