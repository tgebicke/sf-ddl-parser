create or replace view V_USERMAPPING_BV(
	"Component_Acronym",
	"Group_Acronym",
	"Acronym",
	"UserName",
	SYSTEM_ID
) COMMENT='Security view with conditional access levels'
 as
select distinct 
s.COMPONENT_ACRONYM as "Component_Acronym"
,s.GROUP_ACRONYM as "Group_Acronym"
,s.ACRONYM as "Acronym"
,um.USER_ID as"UserName"
,s.SYSTEM_ID
from CORE.VW_CFACTS_USERMAPPING um
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = um.SYSTEM_ID
where um.role not in ('Component Report POC', 'ISPG Fed Staff', 'ISPG Contractor Staff', 'CMS Read Only') 
;