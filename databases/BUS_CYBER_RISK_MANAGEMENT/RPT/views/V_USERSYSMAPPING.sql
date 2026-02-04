create or replace view V_USERSYSMAPPING(
	"Component_Acronym",
	"Group_Acronym",
	"Acronym",
	"UserName"
) COMMENT='System / User mapping details'
 as
SELECT distinct
s.COMPONENT_ACRONYM as "Component_Acronym"
,s.GROUP_ACRONYM as "Group_Acronym"
,um.ACRONYM as "Acronym"
,um.USER_ID as "UserName"
FROM CORE.CFACTS_USERMAPPING um
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = um.SYSTEM_ID
where um.role not in ( 'ISPG Fed Staff', 'ISPG Contractor Staff', 'CMS Read Only');