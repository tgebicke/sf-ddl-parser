create or replace view VW_DAILYDATACHECK_DB(
	TABLENAME,
	DASHBOARD,
	DATA_SOURCENAME,
	VIEW_NAME,
	REPORT_ID,
	REFRESH_DATE
) COMMENT='This view used to check the accuracy on populating data in core tables used for tableau dashboards'
 as
select tdaily.TABLENAME, DASHBOARD, DATA_SOURCENAME, VIEW_NAME, report_id, refresh_date from BUS_CYBER_RISK_MANAGEMENT.RPT.TEMP_DAILYDATACHECK tdaily
join BUS_CYBER_RISK_MANAGEMENT.RPT.VW_DAILYDATACHECK vdaily on vdaily.tablename = tdaily.tablename
;