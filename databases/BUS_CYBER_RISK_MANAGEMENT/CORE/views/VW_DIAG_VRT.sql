create or replace view VW_DIAG_VRT(
	SNAPSHOT_ID,
	DW_ASSET_ID,
	ASSET_VRT,
	CALC_VRT
) COMMENT='Compare current VRT of an asset with  pervious history VRT for same asset.'
 as
select v.snapshot_ID, mdr.dw_asset_id, mdr.VulnRiskTolerance as Asset_VRT,v.VRT as Calc_VRT
from CORE.VW_Assets mdr 
JOIN (select snap.snapshot_ID
,a.DW_ASSET_ID as AssetID
,cast(SUM(IFF(v.ID is null,0,v.DaysSinceDiscovery*cast(v.CVSSV2BASESCORE as float)* s.OATO_Category*IFF(v.exploitAvailable='Yes',2,1)))/IFF(count(1)=0,1,count(1)) as decimal(10,2)) as VRT
FROM VW_REPORTSNAPSHOTS snap
join CORE.VW_VulHist v on v.REPORT_ID = snap.REPORT_ID
	and v.MitigationStatus IN ('Open','Reopened')
	and snap.SNAPSHOT_ID = 5974 
JOIN CORE.VW_Assets a on a.DW_ASSET_ID = v.DW_ASSET_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
WHERE a.Is_Scannable=1 and a.DW_ASSET_ID = 5432
group by a.DW_ASSET_ID,snap.snapshot_ID) v ON v.AssetID=mdr.dw_asset_id;