create or replace task TSK_CRM_IUSG_TENABLE_VUL
	warehouse=CYBER_RISK_MANAGEMENT_06_WH
	schedule='using cron 45 5 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Pull IUSG TENABLE VUL and process into CRM database'
	as CALL CORE.SP_CRM_IUSG_TENABLE_VUL();