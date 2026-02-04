create or replace view V_USERMAPPING_BV_ISPGISSO(
	COMPONENT_ACRONYM,
	ACRONYM,
	USERNAME,
	SYSTEM_ID
) COMMENT='Security view with conditional access levels specific to ISSO'
 as
select s.COMPONENT_ACRONYM,s.ACRONYM,um.USER_ID as USERNAME,s.SYSTEM_ID
FROM CORE.VW_CFACTS_USERMAPPING um
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = um.SYSTEM_ID
WHERE um.role in ('ISPG Fed Staff', 'ISPG Contractor Staff', 'CMS Read Only')
;