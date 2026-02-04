create or replace task TSK_CRM_CONCLUDE
	warehouse=CYBER_RISK_MANAGEMENT_07_WH
	schedule='using cron 20 6 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Complete remaining stored procedures to make CRM data ready for reporting'
	as CALL CORE.SP_CRM_CONCLUDE();