create or replace task TSK_CRM_AXONIUS
	warehouse=CYBER_RISK_MANAGEMENT_09_WH
	schedule='using cron 30 11 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Pull AXONIUS (HIGLAS) and process into CRM database'
	as CALL CORE.SP_CRM_AXONIUS();