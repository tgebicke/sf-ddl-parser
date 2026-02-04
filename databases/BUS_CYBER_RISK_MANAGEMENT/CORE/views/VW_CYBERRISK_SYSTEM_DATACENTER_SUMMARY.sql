create or replace view VW_CYBERRISK_SYSTEM_DATACENTER_SUMMARY(
	GROUP_ACRONYM,
	COMPONENT_ACRONYM,
	"System",
	DATACENTERACRONYM,
	TLC_PHASE,
	"Total_Assets",
	"Total_Vulnerabilites",
	"Critical_Vulnerabilities",
	"High_Vulnerabilities",
	PRIMARY_FISMA_ID,
	DATACENTER_ID,
	SYSTEM_ID,
	PRIMARY_OPERATING_LOCATION
) COMMENT='Shows total assets, vuln, high and critical vuln group by datacenter and system for current end of month, used for CRR.'
 as
select 
s.Group_Acronym 
,s.Component_Acronym 
,s.Acronym as "System"
,dc.Acronym as DataCenterAcronym
,s.TLC_Phase
,ss.Assets as "Total_Assets"
--,ss.AdjAssets as TotalAdjAssets
,(ss.VulCritical + ss.VulHigh) as "Total_Vulnerabilites"
,ss.VulCritical as "Critical_Vulnerabilities"
,ss.VulHigh as "High_Vulnerabilities"
,s.SYSTEM_ID as primary_fisma_id
,dc.SYSTEM_ID as DATACENTER_ID
,s.SYSTEM_ID
,s.Primary_Operating_Location 
FROM TABLE(CORE.FN_CRM_GET_REPORT_ID(1)) r
JOIN CORE.DataCenterSystemSummary ss on ss.report_id = r.REPORT_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = ss.DATACENTER_ID 
JOIN CORE.VW_Systems s on s.SYSTEM_ID = ss.SYSTEM_ID
ORDER BY s.Acronym
,dc.Acronym;