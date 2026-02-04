create or replace task TSK_CRM_CCIC_TENABLE_VUL
	warehouse=CYBER_RISK_MANAGEMENT_05_WH
	schedule='using cron 15 5 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Pull CCIC_TENABLE_VUL and process into CRM database'
	as CALL CORE.SP_CRM_CCIC_TENABLE_VUL();