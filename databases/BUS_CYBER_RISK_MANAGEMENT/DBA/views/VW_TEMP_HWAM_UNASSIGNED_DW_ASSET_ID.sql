create or replace view VW_TEMP_HWAM_UNASSIGNED_DW_ASSET_ID(
	SNAPSHOT_DATE,
	SNAPSHOT_ID,
	DATACATEGORY,
	TOTAL,
	TOTALUNASSIGNED
) COMMENT='Diagnostic View to report count of TEMP_HWAM records that do not have DW_ASSET_ID assigned\t'
 as
SELECT
t.snapshot_date,t.snapshot_id,t.datacategory,t.Total,IFNULL(u.TotalUnassigned,0) as TotalUnassigned
FROM (select snap.snapshot_date,snap.snapshot_id,snap.datacategory,count(1) as Total
FROM CORE.TEMP_HWAM th
join CORE.SNAPSHOT_IDS snap on snap.snapshot_id = th.snapshot_id
group by snap.snapshot_date,snap.snapshot_id,snap.datacategory order by snap.snapshot_id) t
LEFT OUTER JOIN (select snapshot_id,count(1) TotalUnassigned
    from CORE.TEMP_HWAM WHERE dw_asset_id IS NULL
    group by snapshot_id) u on u.snapshot_id = t.snapshot_id
order by t.snapshot_id;