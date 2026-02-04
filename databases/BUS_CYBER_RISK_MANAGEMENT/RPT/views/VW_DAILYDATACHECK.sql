create or replace view VW_DAILYDATACHECK(
	TABLENAME,
	REPORT_ID,
	REFRESH_DATE
) COMMENT='This view used to check the accuracy on populating data in core tables used for tableau dashboards'
 as
select 'RPT.ASSETDETAIL' as TableName, max(r.report_id) report_id, max(refresh_date) as Refresh_date from RPT.ASSETDETAIL ad
join core.report_ids r on date(r.report_date) = date(ad.refresh_date)
UNION
select 'RPT.TEMP_VULN_TRENDING' as TableName, max(report_id) report_id, max(refresh_date) as Refresh_date from rpt.TEMP_VULN_TRENDING
UNION
select 'RPT.TEMP_VULN_FV_ROLLING60DAYS' as TableName, max(r.report_id) report_id, max(refresh_date) as Refresh_date from rpt.TEMP_VULN_FV_ROLLING60DAYS vr
join core.report_ids r on date(r.report_date) = date(vr.refresh_date)
UNION
select 'CORE.SYSTEMSUMMARY' as TableName, max(ss.report_id) report_id, max(report_date) as Refresh_date from core.systemsummary ss
join core.report_ids r on r.report_id = ss.report_id
UNION
select 'CORE.VULHIST' as TableName, max(vh.report_id) report_id, max(report_date) as Refresh_date from core.vulhist vh
join core.report_ids r on r.report_id = vh.report_id
UNION
select 'CORE.ASSETHIST' as TableName, max(ah.report_id) report_id, max(report_date) as Refresh_date from core.assethist ah
join core.report_ids r on r.report_id = ah.report_id
UNION
select 'CORE.POAMHIST' as TableName, max(ph.report_id) report_id, max(report_date) as Refresh_date from core.poamhist ph
join core.report_ids r on r.report_id = ph.report_id
UNION
select 'CORE.ALLOCATEDCONTROL' as TableName, max(AC.report_id) report_id, max(report_date) as Refresh_date from core.allocatedcontrol AC
join core.report_ids r on r.report_id = AC.report_id
;