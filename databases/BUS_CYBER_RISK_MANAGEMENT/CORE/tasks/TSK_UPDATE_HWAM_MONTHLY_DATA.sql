create or replace task TSK_UPDATE_HWAM_MONTHLY_DATA
	schedule='using cron 0 4 L * * America/New_York'
	as call CORE.SP_UPDATE_HWAM_MONTHLY_DATA();