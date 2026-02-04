create or replace view VW_HRS_COMPLIANCE(
	ACRONYM,
	COMPONENT_ACRONYM,
	FIPS_199_OVERALL_IMPACT_RATING,
	AUTH_DECISION,
	HVASTATUS,
	IS_OA_READY,
	IS_OPERATIONALSYSTEM,
	OA_STATUS,
	OATO_CATEGORY,
	OATO_CATEGORY_DESC,
	TLC_PHASE,
	TOTALASSETS,
	REPORT_DATE,
	DATE_AUTH_MEMO_EXPIRES,
	RANKK
) COMMENT='System and Ongoing Auth details at Component level'
 as
SELECT 
s.Acronym
,s.COMPONENT_ACRONYM
,s.FIPS_199_OVERALL_IMPACT_RATING
,s.AUTH_DECISION
,s.HVASTATUS
,IFF(s.IS_OA_READY=1,'Yes','No') Is_OA_Ready
,s.IS_OPERATIONALSYSTEM
,s.OA_STATUS
,s.OATO_CATEGORY
,src.DESCRIPTION OATO_Category_desc
,s.TLC_PHASE
,ss.Assets as TotalAssets
,vsnap.Report_Date Report_Date
,s.DATE_AUTH_MEMO_EXPIRES
,dense_rank()over(order by ss.report_id desc) as rankk
FROM CORE.VW_SYSTEMS s
JOIN (select report_id, system_id, assets  from CORE.VW_SYSTEMSUMMARY) ss on ss.system_id = s.system_id
join (select Report_ID,Report_Date, snapshot_ID, Is_endOfMonth from (select rank()over(partition by DataCategory order by Report_Date desc) rankkForSnap,Report_ID,Report_Date,Snapshot_ID, Is_endOfMonth from CORE.VW_ReportSnapshots
	where DataCategory= 'HWAM')a where rankkForSnap =1) vsnap on vsnap.Report_ID = ss.report_id
JOIN CORE.SystemRiskCategory src on s.oato_category = src.systemriskcategory_id;