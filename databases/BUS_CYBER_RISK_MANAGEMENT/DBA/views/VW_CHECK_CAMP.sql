create or replace view VW_CHECK_CAMP(
	DATE,
	DATA_CENTER,
	DATA_CENTER_CHECK,
	DATACENTER_ACRONYM,
	FISMA,
	FISMA_CHECK,
	SYSTEM_ACRONYM,
	SYSTEM_ACRONYM_CHECK,
	ACCOUNT_NUMBER,
	CFACTS_PRIMARY_OPERATING_LOCATION,
	DERIVED_PRIMARY_OPERATING_LOCATION_ACRONYM,
	DC_POL_CHECK
) COMMENT='Check CAMP (SEC_VW_FISMA_LOOKUPS) for valid data\t'
 as
SELECT ref.DATE,ref.DATA_CENTER
,case coalesce(dc.system_id,'ITSNULL')
    when 'ITSNULL' then 'DATA_CENTER is not valid'
    else 'DATA_CENTER Valid'
end as DATA_CENTER_CHECK
,dc.acronym as DATACENTER_ACRONYM
,ref.FISMA
,case coalesce(s.system_id,'ITSNULL')
    when 'ITSNULL' then 'FISMA is not valid'
    else 'FISMA Valid'
end as FISMA_CHECK
,ref.SYSTEM_ACRONYM
,case coalesce(acro.system_id,'ITSNULL')
    when 'ITSNULL' then 'SYSTEM_ACRONYM is not valid'
    else 'SYSTEM_ACRONYM Valid'
end as SYSTEM_ACRONYM_CHECK
,ref.ACCOUNT_NUMBER
,s.PRIMARY_OPERATING_LOCATION as CFACTS_PRIMARY_OPERATING_LOCATION
,pol.ACRONYM as DERIVED_PRIMARY_OPERATING_LOCATION_ACRONYM
,case
    when dc.system_id = s.primary_operating_location_id then 'DATA_CENTER and PRIMARY_OPERATING_LOCATION match'
    else 'DATA_CENTER and PRIMARY_OPERATING_LOCATION do not match'
end as DC_POL_CHECK
FROM REF_LOOKUPS.SHARED.SEC_VW_FISMA_LOOKUPS ref
left outer join core.systems dc on upper(dc.system_id) = upper(ref.DATA_CENTER)
left outer join core.systems s on upper(s.system_id) = upper(ref.fisma)
left outer join core.systems acro on upper(acro.acronym) = upper(ref.system_acronym)
left outer join core.systems pol on upper(pol.system_id) = upper(s.primary_operating_location_id) 
--left outer join core.systems dcpol on upper(dcpol.system_id) = upper(s.primary_operating_location_id)
;