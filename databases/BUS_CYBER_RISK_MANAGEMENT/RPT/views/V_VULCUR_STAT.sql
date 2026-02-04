create or replace view V_VULCUR_STAT(
	DW_VUL_ID,
	DATEVULCREATED,
	DATACENTERACRONYM,
	SNAPSHOT_DATE,
	SYSTEMACRONYM,
	DATACENTERID,
	SYSTEM_ID,
	ASSET_ID_TATTOO,
	CVE,
	CVSSV2BASE,
	CVSSV3BASE,
	DAYSSINCEDISCOVERY,
	DAYSSINCEDISCOVERY_FILTER,
	DESCRIPTION,
	EXPLOITAVAILABLE,
	FAMILYNAME,
	FIRSTSEEN,
	FISMASEVERITY,
	LASTFOUND,
	MITIGATIONSTATUS,
	OS,
	PLUGINID,
	SIGNATURE,
	SOLUTION,
	SOURCE_TOOL,
	DATACENTER_ID,
	FISMA_ID,
	GROUP_ACRONYM,
	GROUP_NAME,
	COMPONENT_ACRONYM,
	COMPONENT_NAME,
	IS_BOD,
	BODDUEDATE,
	DATEMITIGATED,
	EPSS_SCORE,
	EPSS_FILTER,
	EPSS_PERCENTILE
) COMMENT='current statistics over all vulns including EPSS metrics'
 as
SELECT 
vm.dw_vul_id 
,vm.INSERT_DATE as dateVulCreated 
,dc.Acronym as DataCenterAcronym
,(SELECT max(REPORT_DATE) FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(0))) as SNAPSHOT_DATE
,s.Acronym as SystemAcronym
,dc.System_ID as DataCenterID
,s.System_ID
,a.asset_id_tattoo
,vm.cve
,vm.CVSSV2BASESCORE as CVSSv2Base
,vm.CVSSV3BASESCORE as CVSSv3Base
,vm.DaysSinceDiscovery
,case 
    when vm.DAYSSINCEDISCOVERY <= 15 then '<= 15 days'
    when vm.DAYSSINCEDISCOVERY > 15 and vm.DAYSSINCEDISCOVERY <= 30 then '> 15 and <= 30 days'
    when vm.DAYSSINCEDISCOVERY > 30 and vm.DAYSSINCEDISCOVERY <= 45 then '> 30 and <= 45 days'
    when vm.DAYSSINCEDISCOVERY > 45 and vm.DAYSSINCEDISCOVERY <= 60 then '> 45 and <= 60 days'
    when vm.DAYSSINCEDISCOVERY > 60 and vm.DAYSSINCEDISCOVERY <= 90 then '> 60 and <= 90 days'
    when vm.DAYSSINCEDISCOVERY > 90 then '> 90 days'
    ELSE 'NULL'
    end as DAYSSINCEDISCOVERY_FILTER --added on 082124 as part of CR 959
,NULL as Description
,vm.exploitAvailable
,NULL as familyName
,vm.firstSeen
,vm.FISMAseverity
,vm.lastFound
,vm.MitigationStatus
,a.OS
,plugs.PLUGIN_ID as pluginID -- 230808 was DW_PLUGIN_ID
,NULL as signature
,NULL as Solution
,a.source_tool_VUL as source_tool
,dc.SYSTEM_ID as Datacenter_id
,s.SYSTEM_ID as FISMA_id
,s.Group_Acronym
,s.Group_Name
,s.Component_Acronym 
,s.Component_Name 
,case vm.IS_KEV
	when 0 then 'No'
	Else 'Yes' 
    End as Is_BOD 
,vm.BODDueDate 
,vm.datemitigated
,epss.epss --added on 082124 as part of CR 959
,case 
    when epss.epss <= 0 then '<=0%'
    when epss.epss > 0 and epss.epss <= 0.25 then '> 0% and <= 25%'
    when epss.epss > 0.25 and epss.epss <= 0.50 then '> 25% and <= 50%'
    when epss.epss > 0.50 and epss.epss <= 0.75 then '> 50% and <= 75%'
    when epss.epss > 0.75 and epss.epss <= 1 then '> 75% and <= 100%'
    ELSE 'NULL'
    End as EPSS_FILTER --added on 082124 as part of CR 959
,epss.percentile --added on 082124 as part of CR 959
from CORE.VW_VulMaster vm
JOIN CORE.VW_Assets a on a.DW_ASSET_ID = vm.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = a.DATACENTER_ID
JOIN CORE.VW_Systems s on s.SYSTEM_ID = a.SYSTEM_ID
LEFT OUTER JOIN CORE.VulPlugin plugs on plugs.DW_VUL_ID = vm.DW_VUL_ID
LEFT OUTER JOIN REF_LOOKUPS.PUBLIC.SEC_MV_EPSS_SCORES epss on epss.cve_id = VM.cve --added on 082124 as part of CR 959
;