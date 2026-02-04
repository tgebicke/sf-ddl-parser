create or replace view VW_ASSETDETAIL_ROLLING60DAYS(
	ACR,
	COM_ACR,
	ACR_ALIAS,
	ACRONYM,
	ASSET_ID_TATTOO,
	AWS_ACCOUNTIDS,
	BIOS_GUID,
	BODDUEDATE,
	CLOUD_ACCOUNT_ID,
	COMPONENT_ACRONYM,
	COMPUTER_TYPE,
	CVE,
	CVSS2BASESCORE,
	CVSS3BASESCORE,
	DATA_CENTER_NAME,
	DATACENTER_ID,
	DATECREATED,
	DATEMITIGATED,
	DAYSSINCEDISCOVERY,
	DAYSSINCEDISCOVERY_FILTER,
	OVERDUE_FILTER,
	DELETIONREASON,
	DEVICETYPE,
	DW_ASSET_ID,
	DW_VUL_ID,
	ENVIRONMENT,
	EXPLOITAVAILABLE,
	FAMILYNAME,
	FILTER,
	FIRSTSEEN,
	FISMASEVERITY,
	FQDN,
	HOSTNAME,
	HVASTATUS,
	ID,
	IPV4,
	IPV6,
	IS_BOD,
	IS_MARKETPLACE,
	LASTFOUND,
	MAC,
	MEFSTATUS,
	MITIGATIONSTATUS,
	NETBIOSNAME,
	OATO_CATEGORY,
	OS,
	OS_VERSION,
	PLUGINID,
	RANKK,
	REFRESH_DATE,
	SENSOR_FIRSTSEEN,
	SENSOR_LASTFOUND,
	SIGNATURE,
	SNAPSHOT_ID,
	SOLUTION,
	SOURCE_TOOL,
	SYSTEM_ID,
	FISMA_ID,
	TENABLEUUID,
	TLC_PHASE,
	VULNRISKTOLERANCE,
	EPSS,
	EPSS_FILTER,
	PERCENTILE,
	FIPS_199_OVERALL_IMPACT_RATING,
	OPERATED_BY
) COMMENT='Contains all the Vulnerabilities and asset for latest snapshots with granular CVE IDs/Asset ID/Plug in ID/IPV4/EPSS etc for each system/data Center/component (Fixed Vulns population imited to rolling 60 days)'
 as
select 
    s.Acronym as ACR,
    s.Component_Acronym as COM_ACR,
	substring(s.Acronym,1,1) || '***' as ACR_ALIAS,
	s.ACRONYM,
	Asst.ASSET_ID_TATTOO,
	s.AWS_ACCOUNTIDS,
	Asst.BIOS_GUID,
	Asst.BODDUEDATE,
    Asst.CLOUD_ACCOUNT_ID, -- 241125 CR1038
	Asst.COMPONENT_ACRONYM,
	Asst.COMPUTER_TYPE,
	Asst.CVE,
	Asst.CVSS2BASESCORE,
	Asst.CVSS3BASESCORE,
    IFNULL(Asst.DATA_CENTER_NAME,s.PRIMARY_OPERATING_LOCATION_ACRONYM) as data_center_name, --Datacenter from assets or primary oploc CR #850.
    IFNULL(Asst.DATACENTER_ID,s.primary_operating_location_id) as DATACENTER_ID, --Datacenter id from assets or primary oploc CR #850.
	Asst.DATECREATED,
	Asst.DATEMITIGATED,
	Asst.DAYSSINCEDISCOVERY,
    case 
    when Asst.DAYSSINCEDISCOVERY <= 15 then '<= 15 days'
    when Asst.DAYSSINCEDISCOVERY > 15 and Asst.DAYSSINCEDISCOVERY <= 30 then '> 15 and <= 30 days'
    when Asst.DAYSSINCEDISCOVERY > 30 and Asst.DAYSSINCEDISCOVERY <= 45 then '> 30 and <= 45 days'
    when Asst.DAYSSINCEDISCOVERY > 45 and Asst.DAYSSINCEDISCOVERY <= 60 then '> 45 and <= 60 days'
    when Asst.DAYSSINCEDISCOVERY > 60 and Asst.DAYSSINCEDISCOVERY <= 90 then '> 60 and <= 90 days'
    when Asst.DAYSSINCEDISCOVERY > 90 then '> 90 days'
    ELSE 'NULL'
    end as DAYSSINCEDISCOVERY_FILTER,
    case 
    when Asst.FISMASEVERITY = 'Critical' and Asst.DAYSSINCEDISCOVERY > 15 then 'OVERDUE CRITICAL'
    when Asst.FISMASEVERITY = 'High' and Asst.DAYSSINCEDISCOVERY > 30 then 'OVERDUE HIGH'
    when Asst.FISMASEVERITY = 'Medium' and Asst.DAYSSINCEDISCOVERY > 90 then 'OVERDUE MODERATE'
    when Asst.FISMASEVERITY = 'Low' and Asst.DAYSSINCEDISCOVERY > 365 then 'OVERDUE LOW'
    ELSE 'NOT OVERDUE'
    end as OVERDUE_FILTER, 
	Asst.DELETIONREASON,
	Asst.DEVICETYPE,
	Asst.DW_ASSET_ID,
	Asst.DW_VUL_ID,
    --Asst.DW_ASSET_ID as "FK_AssetID",
    --Asst.DW_VUL_ID as "FK_dw_vul_number",
	Asst.ENVIRONMENT,
	Asst.EXPLOITAVAILABLE,
	Asst.FAMILYNAME,
	Asst.FILTER,
	Asst.FIRSTSEEN,
	Asst.FISMASEVERITY,
	Asst.FQDN,
	Asst.HOSTNAME,
	s.HVASTATUS,
	Asst.ID,
	Asst.IPV4,
	Asst.IPV6,
	Asst.IS_BOD,
	s.IS_MARKETPLACE,
	Asst.LASTFOUND,
	Asst.MAC,
	s.MEFSTATUS,
	Asst.MITIGATIONSTATUS,
	Asst.NETBIOSNAME,
	Asst.OATO_CATEGORY,
	Asst.OS,
	Asst.OS_VERSION,
	Asst.PLUGINID,
	Asst.RANKK,
	Asst.REFRESH_DATE,
	Asst.SENSOR_FIRSTSEEN,
	Asst.SENSOR_LASTFOUND,
	Asst.SIGNATURE,
	Asst.SNAPSHOT_ID,
	Asst.SOLUTION,
	Asst.SOURCE_TOOL,
	Asst.SYSTEM_ID,
    Asst.SYSTEM_ID FISMA_ID,
	Asst.TENABLEUUID,
	s.TLC_PHASE,
	Asst.VULNRISKTOLERANCE
    ,epss.epss
    ,case 
    when epss.epss <= 0 then '<=0%'
    when epss.epss > 0 and epss.epss <= 0.25 then '> 0% and <= 25%'
    when epss.epss > 0.25 and epss.epss <= 0.50 then '> 25% and <= 50%'
    when epss.epss > 0.50 and epss.epss <= 0.75 then '> 50% and <= 75%'
    when epss.epss > 0.75 and epss.epss <= 1 then '> 75% and <= 100%'
    ELSE 'NULL'
    end as epss_FILTER
    ,epss.percentile
    ,s.FIPS_199_OVERALL_IMPACT_RATING -- 250103 CR1059
    ,s.OPERATED_BY, -- 250103 CR1059
 from (select * from RPT.AssetDetail where lower(MitigationStatus) in ('open', 'reopened') or (lower(MitigationStatus) = 'fixed' and datemitigated > (current_date() - 60)))asst
 right outer join (select SYSTEM_ID,Acronym,Component_Acronym,Is_MarketPlace,HVAStatus,MEFStatus,TLC_Phase,aws_accountids, PRIMARY_OPERATING_LOCATION_ACRONYM, primary_operating_location_id
 ,OPERATED_BY,FIPS_199_OVERALL_IMPACT_RATING -- 250103 CR1059
 from CORE.vw_Systems) s ON s.SYSTEM_ID = asst.SYSTEM_ID 
 LEFT OUTER JOIN REF_LOOKUPS.PUBLIC.SEC_MV_EPSS_SCORES epss on epss.cve_id = Asst.cve
;