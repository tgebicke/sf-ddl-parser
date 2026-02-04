create or replace view VW_SEC_USERSYSMAPPING_VATDC(
	DATACENTER_ACRONYM,
	DATACENTER_ID,
	ACRONYM,
	SYSTEM_ID,
	USERID
) COMMENT='Security view for specifically crated for Data center users (Details provided by VAT team)'
 as
select distinct
 A.DATACENTER_ACRONYM --as "DataCenter Acronym"
,A.DATACENTER_ID --as "DataCenterUID"
,S.Acronym --as "System Acronym"
,S.SYSTEM_ID --as "SystemUID"
,SU.UserId --as "UserName"
from CORE.VW_SYSTEMS S
join CORE.VW_ASSETS A on A.system_id = S.system_id
join rpt.VAT_SYSTEMUSERS SU on S.SYSTEM_ID = SU.SYSTEM_ID
where S.Is_ExcludeFromReporting = 0 and S.Is_PhantomSystem=0 and SU.UserId is not null
;