create or replace view VW_RAW_EXCEPTION_SUMMARY(
	SNAPSHOT_ID,
	SNAPSHOT_DATE,
	DATACATEGORY,
	MSGTYPE,
	MSG,
	TOTAL
) COMMENT='View to report data errors/warnings in RAW_HWAM and RAW_TENABLE_VUL tables in summary form (Historical)\t'
 as
select snap.snapshot_id,snap.snapshot_date::date as snapshot_date,snap.datacategory,t.MsgType,t.Msg,t.Total
FROM CORE.SNAPSHOT_IDS snap
JOIN
(
select r.snapshot_id,'Error' as MsgType,f.value::string MSG,count(1) Total 
FROM CORE.RAW_HWAM r
JOIN table(flatten(r.data_error_array,outer=>true)) as f
group by r.snapshot_id,f.value::string 
UNION ALL
select r.snapshot_id,'Warn' as MsgType,f.value::string MSG,count(1) Total 
FROM CORE.RAW_HWAM r
JOIN table(flatten(r.data_warning_array,outer=>true)) as f
group by r.snapshot_id,f.value::string 
UNION ALL
select r.snapshot_id,'Error' as MsgType,f.value::string MSG,count(1) Total 
FROM CORE.RAW_TENABLE_VUL r
JOIN table(flatten(r.data_error_array,outer=>true)) as f
group by r.snapshot_id,f.value::string 
UNION ALL
select r.snapshot_id,'Warn' as MsgType,f.value::string MSG,count(1) Total 
FROM CORE.RAW_TENABLE_VUL r
JOIN table(flatten(r.data_warning_array,outer=>true)) as f
group by r.snapshot_id,f.value::string 
) t on t.snapshot_id = snap.snapshot_id
WHERE snap.snapshot_date >= current_date()
order by snap.snapshot_id,snap.snapshot_date::date,snap.datacategory,t.MsgType,t.MSG;