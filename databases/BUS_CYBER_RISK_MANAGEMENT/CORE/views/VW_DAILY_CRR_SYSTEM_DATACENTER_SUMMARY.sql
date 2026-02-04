create or replace view VW_DAILY_CRR_SYSTEM_DATACENTER_SUMMARY(
	GROUP_ACRONYM,
	COMPONENT_ACRONYM,
	"System",
	DATACENTERACRONYM,
	TLC_PHASE,
	"Total Assets",
	"Total Vulnerabilites",
	"Critical Vulnerabilities",
	"High Vulnerabilities",
	DATACENTER_ID,
	PRIMARY_FISMA_ID,
	SYSTEM_ID,
	PRIMARY_OPERATING_LOCATION
) COMMENT='Returns multiple vuln catagory daily summary for every system and datacenter combine.'
 as
select 
s.Group_Acronym 
,s.Component_Acronym 
,s.Acronym as "System"
,dc.Acronym as DataCenterAcronym
,s.TLC_Phase
,ss.Assets as "Total Assets"
--,ss.AdjAssets as TotalAdjAssets
,(ss.VulCritical + ss.VulHigh) as "Total Vulnerabilites"
,ss.VulCritical as "Critical Vulnerabilities"
,ss.VulHigh as "High Vulnerabilities"
,dc.SYSTEM_ID as datacenter_id
,s.SYSTEM_ID as primary_fisma_id
,s.SYSTEM_ID
,s.Primary_Operating_Location 
FROM table(CORE.FN_CRM_GET_REPORT_ID(0)) r
join CORE.DataCenterSystemSummary ss on ss.REPORT_ID = r.REPORT_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = ss.DATACENTER_ID
JOIN (SELECT SYSTEM_ID,Acronym,TLC_Phase,Primary_Operating_Location,Group_Acronym,Component_Acronym
	    FROM CORE.VW_Systems) s ON s.SYSTEM_ID = ss.SYSTEM_ID
	--WHERE Is_ExcludeFromReporting = 0 and Is_PhantomSystem = 0) 
;