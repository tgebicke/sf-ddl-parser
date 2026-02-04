create or replace task TSK_CRM_KEV_CATALOG
	warehouse=CYBER_RISK_MANAGEMENT_02_WH
	schedule='using cron 15 3 * * * America/New_York'
	STATEMENT_TIMEOUT_IN_SECONDS=3600
	COMMENT='Pull KEV (BOD) CATALOG and process into CRM database'
	as CALL CORE.SP_CRM_KEV_CATALOG();