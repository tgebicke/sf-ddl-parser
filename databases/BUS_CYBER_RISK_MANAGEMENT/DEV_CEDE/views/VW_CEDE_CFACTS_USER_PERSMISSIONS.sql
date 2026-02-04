create or replace view VW_CEDE_CFACTS_USER_PERSMISSIONS(
	REPORTDATE,
	ACRONYM,
	AUTHORIZATION_PACKAGE,
	COMPONENT_ACRONYM,
	GROUP_ACRONYM,
	TLC_PHASE,
	CFACTS_UID,
	USERNAME,
	ROLE
) COMMENT='Security view for user permission to CEDE dashboards'
 as
SELECT distinct
(select Report_Date from TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as ReportDate
,s.ACRONYM as Acronym
,s.AUTHORIZATION_PACKAGE as Authorization_Package
,s.COMPONENT_ACRONYM as Component_Acronym
,s.GROUP_ACRONYM as Group_Acronym
,s.TLC_PHASE as TLC_Phase
,case SUBSTRING(s.SYSTEM_ID,1,4)
	when '0000' then NULL
	Else s.SYSTEM_ID
End as CFACTS_UID
,um.USER_ID as UserName
,um.ROLE as Role
FROM CORE.VW_SYSTEMS s
JOIN BUS_CYBER_RISK_MANAGEMENT.DEV_RPT.V_SEC_USERSYSMAPPING_ALL uma on uma.acronym = s.acronym
JOIN CORE.CFACTS_USERMAPPING um on um.USER_ID = uma.username and um.role = uma.role
--WHERE um.USER_ID = 'S1T6' -- Julianne
;