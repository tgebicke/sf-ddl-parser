create or replace view V_MONTHLY_CRR_OA(
	"join_ID",
	"acronym",
	"Archer_Tracking_ID",
	"auth_decision",
	"Component_Acronym",
	"Group_Acronym",
	"HVAStatus",
	"In_CMS_Cloud",
	"ISSO Count",
	"OA_Status",
	"fk_prim_id",
	"cve",
	"cve_count",
	"MitigationStatus",
	"FISMAseverity",
	"snapshotdate"
) COMMENT='Using legacy V_ standard naming to expediate migration'
 as
select
s.SYSTEM_ID as "join_ID"
,s.ACRONYM as "acronym"
,s.ARCHER_TRACKING_ID as "Archer_Tracking_ID"
,s.AUTH_DECISION as "auth_decision"
,s.COMPONENT_ACRONYM as "Component_Acronym"
,s.GROUP_ACRONYM as "Group_Acronym"
,s.HVASTATUS as "HVAStatus"
,s.IN_CMS_CLOUD as "In_CMS_Cloud"
,s.ISSO_COUNT as "ISSO Count"
,s.OA_STATUS as "OA_Status"
,v.SYSTEM_ID as "fk_prim_id"
,v.CVE as "cve"
,v.CVE_COUNT as "cve_count"
,v.MITIGATIONSTATUS as "MitigationStatus"
,v.FISMASEVERITY as "FISMAseverity"
,v.REPORT_DATE as "snapshotdate"
FROM (select SYSTEM_ID
    ,ACRONYM
    ,ARCHER_TRACKING_ID
    ,AUTH_DECISION
    ,COMPONENT_ACRONYM
    ,GROUP_ACRONYM
    ,HVASTATUS
    ,IN_CMS_CLOUD
    ,ISSO_COUNT
    ,OA_STATUS
    FROM CORE.VW_SYSTEMS
    WHERE TLC_PHASE <> 'Retire') s
left outer join (select a.SYSTEM_ID,vh.CVE,count(vh.CVE) as CVE_COUNT,vh.MITIGATIONSTATUS,vh.FISMASEVERITY,r.REPORT_DATE
    FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) r
    join CORE.VW_VULHIST vh on vh.REPORT_ID = r.REPORT_ID
    join CORE.VULMASTER vm on vm.DW_VUL_ID = vh.DW_VUL_ID
    join CORE.ASSET a on a.DW_ASSET_ID = vm.DW_ASSET_ID
    where vh.FISMASEVERITY is not null
    group by a.SYSTEM_ID,vh.CVE,vh.MITIGATIONSTATUS,vh.FISMASEVERITY,r.REPORT_DATE) v on v.SYSTEM_ID = s.SYSTEM_ID
;