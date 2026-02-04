create or replace view VW_FISMAREPORT_DCWITHTIMERANGE(
	DATACENTERACRONYM,
	REPORT_DATE,
	ASSET_ID_TATTOO,
	BODDUEDATE,
	COMPONENT_ACRONYM,
	COMPONENT_NAME,
	CVE,
	CVSSV2BASESCORE,
	CVSSV3BASESCORE,
	DATACENTER_ID,
	DAYSSINCEDISCOVERY,
	DESCRIPTION,
	DNSNAME,
	DW_ASSET_ID,
	DW_VUL_ID,
	EXPLOITAVAILABLE,
	FAMILYNAME,
	FIRSTSEEN,
	FISMASEVERITY,
	GROUP_ACRONYM,
	GROUP_NAME,
	ID,
	IP,
	IS_BOD,
	LASTFOUND,
	MACADDRESS,
	MITIGATIONSTATUS,
	NETBIOSNAME,
	OS,
	PLUGIN_ID,
	REPORT_ID,
	SIGNATURE,
	SOLUTION,
	SOURCE_TOOL,
	SYSTEM_ID,
	SYSTEMACRONYM
) COMMENT='Fisma Report Vulnerability asset details some dc with specific time range'
 as
SELECT 
dc.Acronym as DATACENTERACRONYM
,r.REPORT_DATE::date as REPORT_DATE
,ah.ASSET_ID_TATTOO
,kev.BODDUEDATE::date as BODDUEDATE
,s.COMPONENT_ACRONYM
,s.COMPONENT_NAME
,vm.CVE
,v.CVSSV2BASESCORE
,v.CVSSV3BASESCORE
,ah.DATACENTER_ID
--,vm.DATEMITIGATED -- Dont need this if only reporting (open/reopened)
,DATEDIFF(day,vm.firstseen,v.lastFound) as DAYSSINCEDISCOVERY
,NULL as DESCRIPTION
,ah.FQDN as DNSNAME
,ah.DW_ASSET_ID
,vm.DW_VUL_ID
,v.EXPLOITAVAILABLE
,NULL as FAMILYNAME
,vm.FIRSTSEEN::date as FIRSTSEEN
,v.FISMASEVERITY
,s.GROUP_ACRONYM -- 230623
,s.GROUP_NAME
,v.ID
,ah.IPv4 as IP
,case coalesce(kev.ID,0)
    WHEN 0 THEN 0
    ELSE 1
end::boolean as IS_BOD
,v.LASTFOUND::date as LASTFOUND
,ah.MACADDRESS
,v.MITIGATIONSTATUS
,ah.NETBIOSNAME
,ah.OS
,plugs.PLUGIN_ID
,r.REPORT_ID
,NULL as SIGNATURE
,NULL as SOLUTION
,'Tenable' as SOURCE_TOOL -- 230623
,ah.SYSTEM_ID
,s.Acronym as SYSTEMACRONYM
FROM (select * from CORE.REPORT_IDS 
where 
--
-- 240320 The following dates were incorrect
--
--REPORT_DATE::DATE ='7/3/2023' -- Obtained from legacy database
--OR REPORT_DATE::DATE = '7/17/2023' -- Obtained from legacy database
--OR REPORT_DATE::DATE = '9/11/2023' -- Obtained from legacy database
--OR REPORT_DATE::DATE = '10/9/2023' -- Obtained from legacy database
--OR REPORT_DATE::DATE = '10/11/2023' -- Obtained from legacy database
--REPORT_DATE::DATE = '11/6/2023' -- SDW was rolled-out 11/01/2023
-- or REPORT_DATE::DATE = '12/18/2023' 
--
-- 240320 The following are the correct dates
--
--REPORT_DATE::DATE = '11/17/2023'
--REPORT_DATE::DATE = '12/29/2023'
--
-- 240325
report_date::date >= '2024-02-21'::date and report_date::date <= '2024-03-21'::date
) r
JOIN CORE.VULHIST v on v.REPORT_ID = r.REPORT_ID
JOIN CORE.VulMaster vm on vm.DW_VUL_ID = v.DW_VUL_ID
LEFT OUTER JOIN CORE.KEV_CATALOG kev on kev.CVE = vm.CVE -- Do not check IS_DELETED = 0. We want to know if it was a BOD at that point in time
JOIN CORE.VW_ASSETHIST ah on ah.REPORT_ID = r.REPORT_ID and ah.DW_ASSET_ID = vm.DW_ASSET_ID
JOIN CORE.VW_SYSTEMS dc on dc.SYSTEM_ID = ah.DATACENTER_ID
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = ah.SYSTEM_ID
LEFT OUTER JOIN CORE.VULPLUGINS_COALESCED plugs on plugs.DW_VUL_ID = v.DW_VUL_ID
where v.mitigationstatus in ('open','reopened') 
-- 240325 The following filter used in 3/20/24 request
-- 240325 and (dc.Acronym in ('EDC4', 'LMDC', 'DRaaS-CACHE', 'HIGLAS')) -- or s.Acronym = 'LMDC');
-- 240325
and (dc.acronym in ('AWS','AWS GovCloud') or s.acronym in ('AWS','AWS GovCloud','Acquia','CMS MAG','FFM','HETS','IDM'))
;