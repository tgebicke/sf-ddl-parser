create or replace view VW_DAILY_CRR_VUL_DETAIL(
	ID,
	DATECREATED,
	DATACENTER_ID,
	DATACENTERACRONYM,
	COMMONNAME,
	PRIMARY_FISMA_ID,
	ACRONYM,
	ASSET_ID_TATTOO,
	IP,
	CVE,
	DNSNAME,
	MACADDRESS,
	FISMASEVERITY,
	SIGNATURE,
	CVSS3BASESCORE,
	NETBIOSNAME,
	FAMILYNAME,
	EXPLOITAVAILABLE,
	DATASOURCE,
	ROWDISPOSITION,
	FIRSTSEEN,
	LASTFOUND,
	DAYSSINCEDISCOVERY,
	OS,
	PLUGINID,
	DESCRIPTION,
	SOLUTION,
	MITIGATIONSTATUS,
	VULN_STAGEDC_ID,
	VULN_STAGEDC_DATECREATED,
	REPORTID,
	IS_BOD,
	BODDUEDATE,
	DATEMITIGATED
) COMMENT='Returns current detail  of all vulnerability.'
 as
SELECT v.ID
,v.FIRSTSEEN as dateCreated
,dc.SYSTEM_ID as datacenter_id
,dc.Acronym as DataCenterAcronym
,dc.CommonName
,pf.SYSTEM_ID as primary_fisma_id
,pf.Acronym
,a.asset_id_tattoo
,a.IPv4 as ip
,v.cve
,a.fqdn as dnsName
,a.macAddress
,v.FISMAseverity
,NULL as signature 
,v.CVSSV3BASESCORE as cvss3basescore
,a.netbiosname
,NULL as familyName 
,v.exploitAvailable
,NULL as dataSource 
,NULL as RowDisposition 
,v.firstSeen
,v.lastFound
,v.DaysSinceDiscovery
,a.OS
,plugs.PLUGIN_ID as pluginid
,NULL as Description 
,NULL as Solution 
,v.mitigationstatus
,NULL as VULN_StageDC_ID 
,NULL as VULN_StageDC_dateCreated 
--,v.datacenter_id
--,v.SYSTEM_ID as primary_fisma_Id
,snap.Report_ID as ReportID
,case coalesce(cast(bodcat.ID as varchar),'No')
	when 'No' then 'No'
	Else 'Yes' 
End as Is_BOD 
,bodcat.BODDueDate 
,vm.datemitigated 
FROM CORE.VW_VulHist v
join TABLE(FN_CRM_GET_REPORT_ID(0)) snap on snap.Report_ID = v.Report_ID
JOIN CORE.VW_Assets a on a.dw_asset_id = v.DW_ASSET_ID
JOIN CORE.VW_Systems dc on dc.SYSTEM_ID = v.datacenter_id
JOIN CORE.VW_Systems pf on pf.SYSTEM_ID = v.SYSTEM_ID
JOIN CORE.VW_VulMaster vm on vm.DW_VUL_ID = v.DW_VUL_ID -- and vm.DeletionReason IS NULL  
LEFT OUTER JOIN CORE.KEV_Catalog bodcat on bodcat.CVE = vm.cve 
LEFT OUTER JOIN CORE.VulPlugin plugs on plugs.DW_VUL_ID = v.DW_VUL_ID
where LOWER(v.MitigationStatus) IN ('open','reopened')
and v.FISMAseverity IN ('Critical','High');