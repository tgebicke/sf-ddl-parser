create or replace view VW_DATACENTERS(
	SYSTEM_ID,
	ACRONYM,
	COMMONNAME,
	IS_DATACENTER,
	TOTALSYSTEMSINCFACTS,
	TOTALSYSTEMSINDISPOSITION,
	TOTALSYSTEMSREPORTED,
	TOTALASSETSREPORTED,
	"Critical Vulnerabilities",
	"High Vulnerabilities",
	CFACTS_AUTHORIZATION_PACKAGE,
	CFACTS_PRIMARY_OPERATING_LOCATION,
	CFACTS_CLOUD_SERVICE_PROVIDER
) COMMENT='Returns total systems, retire systems, assets and other datacenter summary based on primary operating location.'
 as
SELECT
dc.system_id
,dc.Acronym
,dc.CommonName
,dc.Is_DataCenter
,coalesce(dcSys.TotalSystems,0) as TotalSystemsInCFACTS
,coalesce(dcSysDecom.TotalSystems,0) as TotalSystemsInDisposition
,coalesce(cds."TotalSystems",0) as TotalSystemsReported
,coalesce(cds."TotalAssets",0) as TotalAssetsReported
,coalesce(cds."Critical Vulnerabilities",0) as "Critical Vulnerabilities"
,coalesce(cds."High Vulnerabilities",0) as "High Vulnerabilities"
,dc.Authorization_Package as CFACTS_Authorization_Package
,dc.Primary_Operating_Location as CFACTS_Primary_Operating_Location
,dc.Cloud_Service_Provider as CFACTS_Cloud_Service_Provider

FROM CORE.VW_Systems dc

LEFT OUTER JOIN (select Primary_Operating_Location as datacenter_id,count(1) as TotalSystems
	FROM Systems
	GROUP BY Primary_Operating_Location) dcSys on dcSys.datacenter_id = dc.SYSTEM_ID

LEFT OUTER JOIN (select Primary_Operating_Location as datacenter_id,count(1) as TotalSystems
	FROM Systems
	WHERE TLC_Phase = 'Retire'
	GROUP BY Primary_Operating_Location) dcSysDecom on dcSysDecom.datacenter_id = dc.SYSTEM_ID

LEFT OUTER JOIN rpt.V_CyberRisk_DataCenter_Summary cds on cds."datacenter_id" = dc.SYSTEM_ID --CFACTS_UID

WHERE dc.Is_DataCenter = 1
ORDER BY dc.Acronym;