create or replace task TSK_CRM_CROWDSTRIKE
	warehouse=CYBER_RISK_MANAGEMENT_08_WH
	schedule='using cron 30 2 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Pull CROWDSTRIKE and process into CRM database'
	as CALL CORE.SP_CRM_CROWDSTRIKE();