create or replace view V_SEC_USERSYSMAPPING_ALL(
	ACRONYM,
	USERNAME,
	MEMBER
) COMMENT='Security view with role-based access levels and users'
 as
SELECT distinct
um.ACRONYM
,um.USER_ID as USERNAME
,FALSE as MEMBER
FROM CORE.CFACTS_USERMAPPING um
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = um.SYSTEM_ID
where um.role not in ( 'ISPG Fed Staff', 'ISPG Contractor Staff', 'CMS Read Only')
--and TLC_Phase <> 'Retire' --231122_1130  CR 788
Union All
select distinct
syst.ACRONYM
,EC.USERNAME
,EC.MEMBER
from RPT.CFACTS_EXCLUSIVECLUB EC 
LEFT JOIN CORE.VW_SYSTEMS syst on 1=1
where Member = 1
--and TLC_Phase <> 'Retire'; --231122_1130 CR 788
;