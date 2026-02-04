create or replace view VW_TEMP_HWAM_MATCHING_RESULTS(
	DATACATEGORY,
	MATCHMETHOD,
	MATCHORDER,
	TOTAL
) as
select snap.datacategory,MATCHMETHOD,MATCHORDER,count(1) Total
from CORE.TEMP_HWAM th
join CORE.SNAPSHOT_IDS snap on snap.snapshot_id = th.snapshot_id
group by snap.datacategory,MATCHMETHOD,MATCHORDER
order by snap.datacategory,MATCHORDER;
;