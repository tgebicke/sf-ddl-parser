create or replace view V_CFACTS_USERMAPPING(
	ID,
	"Component_Acronym",
	"EntryType",
	"Group_Acronym",
	"Role",
	"Acronym",
	"FK_userID",
	"UserName",
	"FK_SystemID",
	CFACTS_UID
) COMMENT='User/System mapping structure for permissions'
 as
SELECT 
um.ID as "ID"
,s.COMPONENT_ACRONYM as "Component_Acronym"
,null as "EntryType"
,s.GROUP_ACRONYM as "Group_Acronym"
,um.ROLE as "Role"
,um.ACRONYM as "Acronym"
,um.USER_ID as "FK_userID"
,um.USER_ID as "UserName"
,um.SYSTEM_ID as "FK_SystemID"
,um.SYSTEM_ID as "CFACTS_UID"
FROM CORE.CFACTS_USERMAPPING um
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = um.SYSTEM_ID;