create or replace task TSK_CRM_INITIATE
	warehouse=CYBER_RISK_MANAGEMENT_01_WH
	schedule='using cron 15 2 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Initialize CRM database by generating a REPORT_ID (snapshot identifier) and pull fundamental data like CFACTS'
	as CALL CORE.SP_CRM_INITIATE();