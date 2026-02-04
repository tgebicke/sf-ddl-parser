create or replace task TSK_CRM_MAINTENANCE
	warehouse=CYBER_RISK_MANAGEMENT_12_WH
	schedule='using cron 30 23 * * 6 America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Perform routine maintenance and cleanup of the CRM database'
	as CALL CORE.SP_CRM_MAINTENANCE();