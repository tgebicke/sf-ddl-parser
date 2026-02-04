create or replace view VW_CEDE_CFACTS_USER_PERSMISSIONS(
	REPORTDATE,
	ACRONYM,
	AUTHORIZATION_PACKAGE,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	TLC_PHASE,
	SYSTEM_ID,
	CFACTS_USER_ID,
	ROLE
) COMMENT='Current CFACTS users mapping to system and role for CEDE'
 as
SELECT
snap.SNAPSHOT_DATE as ReportDate -- This date can be different from ReportDate associated with SystemHist
,s.Acronym
,s.Authorization_Package
,s.Component_Acronym 
,s.Group_Acronym 
,s.TLC_Phase
,case SUBSTRING(s.SYSTEM_ID,1,4)
	when '0000' then NULL
	Else s.SYSTEM_ID
End as SYSTEM_ID
,ul.user_id as CFACTS_USER_ID
,um.Role
FROM RPT.V_CFACTS_USERLIST ul -- 231027 was CORE.VW_CFACTS_UserList ul
JOIN CORE.VW_CFACTS_UserMapping um on um.USER_ID = ul.USER_ID
--JOIN CORE.REPORTSNAPSHOTS rs on rs.report_id = um.report_id
JOIN CORE.VW_Systems s on s.SYSTEM_ID = um.SYSTEM_ID -- and s.Is_ExcludeFromReporting = 0 and s.Is_PhantomSystem = 0
JOIN CORE.VW_CAATHist caat on s.SYSTEM_ID = caat.SYSTEM_ID
JOIN CORE.VW_REPORTSNAPSHOTS rs on caat.REPORTID = (select MAX(RS.REPORT_ID) from CORE.VW_REPORTSNAPSHOTS RS WHERE RS.SnapShot_ID = snap.SNAPSHOT_ID)
JOIN CORE.SNAPSHOT_IDS snap on snap.SNAPSHOT_ID = rs.Snapshot_ID;