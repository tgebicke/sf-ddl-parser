create or replace view VW_VULPLUGINS_MASTER_HIGLAS(
	DW_PLUGIN_VUL_ID,
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
	ASSET_ID_TATTOO,
	FQDN,
	HOSTNAME,
	NETBIOSNAME,
	IPV4,
	IPV6,
	DEVICETYPE,
	OS,
	DW_ASSET_ID,
	PLUGIN_ID,
	FISMASEVERITY_V3,
	FISMASEVERITY_V2,
	CVE,
	PLUGIN_MITIGATIONSTATUS,
	CVSSV2BASESCORE,
	CVSSV3BASESCORE,
	INSERT_DATE,
	FIRSTSEEN,
	LASTFOUND,
	DATEMITIGATED,
	DATEMODIFIED,
	DATEREOPENED,
	DAYSSINCEDISCOVERY,
	EXPLOITAVAILABLE,
	REPOSITORY_ID,
	REPOSITORY_NAME,
	DATACENTER_ID,
	SYSTEM_ID,
	IS_FROM_AWS_FEED,
	TOTAL_PLUGIN_COUNT,
	FIXED_PLUGIN_COUNT,
	OPEN_PLUGIN_COUNT,
	DELETED_PLUGIN_COUNT,
	MITIGATIONSTATUS,
	EXTENDED_MITIGATIONSTATUS,
	FISMASEVERITY
) COMMENT='Temporary View reports Tenable vulnerabilities from VULPLUGINS_MASTER for HIGLAS.\t'
 as
SELECT
vpm.DW_PLUGIN_VUL_ID
,a.datacenter_acronym
,a.system_acronym
,a.asset_id_tattoo
,a.fqdn
,a.hostname
,a.netbiosname
,a.ipv4
,a.ipv6
,a.devicetype
,a.os
,vpm.DW_ASSET_ID
,vpm.PLUGIN_ID 
,vpm.FISMASEVERITY as FISMASEVERITY_V3
,(select CORE.FN_CRM_FISMASEVERITY('2.0',vpm.CVSSV2BASESCORE)) as FISMASEVERITY_V2
,f.value::string CVE
--,ARRAY_TO_STRING(vpm.CVE,',') as CVE
,vpm.mitigationstatus as Plugin_MitigationStatus
,vpm.CVSSV2BASESCORE
,vpm.CVSSV3BASESCORE
,substring(vpm.INSERT_DATE::varchar,1,16) as INSERT_DATE
,substring(vpm.FIRSTSEEN::varchar,1,16) as FIRSTSEEN
,substring(vpm.LASTFOUND::varchar,1,16) as LASTFOUND
,substring(vpm.DATEMITIGATED::varchar,1,16) as DATEMITIGATED
,substring(vpm.DATEMODIFIED::varchar,1,16) as DATEMODIFIED
,substring(vpm.DATEREOPENED::varchar,1,16) as DATEREOPENED
,vpm.DAYSSINCEDISCOVERY
,vpm.EXPLOITAVAILABLE
,vpm.REPOSITORY_ID
,vpm.REPOSITORY_NAME
,a.DATACENTER_ID
,a.SYSTEM_ID
,vpm.IS_FROM_AWS_FEED
,vm.total_plugin_count
,vm.fixed_plugin_count
,vm.open_plugin_count
,vm.deleted_plugin_count
,vm.mitigationstatus
,vm.extended_mitigationstatus
,vm.fismaseverity
FROM CORE.VULPLUGINS_MASTER vpm
join table(flatten(cve,outer=>true)) as f
JOIN CORE.VW_ASSETS a on a.DW_ASSET_ID = vpm.DW_ASSET_ID
left OUTER JOIN CORE.VULMASTER vm on vm.dw_asset_id = vpm.dw_asset_id and vm.CVE = f.value::string
WHERE vpm.DELETIONREASON IS NULL and a.system_acronym = 'HIGLAS';