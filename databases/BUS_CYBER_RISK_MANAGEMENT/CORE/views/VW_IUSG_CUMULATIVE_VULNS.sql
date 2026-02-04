create or replace view VW_IUSG_CUMULATIVE_VULNS(
	ACCEPT_RISK_RULE_COMMENT,
	ACCEPTRISK,
	ACCOUNTID,
	ACRSCORE,
	ASSETEXPOSURESCORE,
	BASESCORE,
	BID,
	CHECKTYPE,
	CPE,
	CVE,
	CVSSV3BASESCORE,
	CVSSV3TEMPORALSCORE,
	CVSSV3VECTOR,
	CVSSVECTOR,
	DATACENTER_ID,
	DESCRIPTION,
	DNSNAME,
	EXPLOIT_AVAILABLE,
	EXPLOITEASE,
	EXPLOITFRAMEWORKS,
	FAMILY_ID,
	FAMILY_NAME,
	FAMILY_TYPE,
	FIRST_SEEN,
	HAS_BEEN_MITIGATED,
	HOSTUNIQUENESS,
	HOSTUUID,
	INSTANCEID,
	IP,
	IPS,
	KEYDRIVERS,
	LAST_SEEN,
	MACADDRESS,
	NETBIOSNAME,
	OPERATING_SYSTEM,
	PATCHPUB_DATE,
	PLUGIN_ID,
	PLUGIN_INFO,
	PLUGIN_MOD_DATE,
	PLUGIN_NAME,
	PLUGIN_PUB_DATE,
	PLUGINTEXT,
	PORT,
	PROTOCOL,
	RECASTRISK,
	RECASTRISKRULECOMMENT,
	REPOSITORY_DATAFORMAT,
	REPOSITORY_DESCRIPTION,
	REPOSITORY_ID,
	REPOSITORY_NAME,
	RISKFACTOR,
	SEEALSO,
	SEVERITY_DESCRIPTION,
	SEVERITY_ID,
	SEVERITY_NAME,
	SOLUTION,
	STIGSEVERITY,
	SYNOPSIS,
	SYSTEM_ID,
	TEMPORAL_SCORE,
	UNIQUENESS,
	UUID,
	VERSION,
	VPR_SCORE,
	VPRCONTEXT,
	VULN_PUB_DATE,
	VULNUNIQUENESS,
	VULNUUID,
	XREF,
	FILENAME,
	S3_FILE_CREATE,
	SF_FILE_LOAD,
	RAW_VULNS
) COMMENT='CRITICAL; Replacement for APP_CDM.SHARED.SEC_VW_IUSG_CUMULATIVE_VULNS for missing InstanceID and AccountID\t'
 as
--
-- 240724 CR940
--
-- UUID can be Empty/Null
-- Some ACCOUNTID are not in SEC_VW_FISMA_LOOKUPS e.g. 491375690626
-- 90191 Amazon Web Services EC2 Instance Metadata Enumeration (Unix)
-- 90427 Amazon Web Services EC2 Instance Metadata Enumeration (Windows)
-- 90191/90427 has 'instance-id' and/or 'instanceId'
-- Use SEC_VW_HWAM_AWS instead of SEC_VW_FISMA_LOOKUPS
-- Not all instanceID from SEC_VW_IUSG_TENABLE_PLUGIN_METADATA are in SEC_VW_HWAM_AWS based on instanceID
--  so also try to find instanceID in SEC_VW_HWAM_AWS based on DNSNAME
-- There is no date filter on SEC_VW_IUSG_TENABLE_PLUGIN_METADATA so we were joining on history going back to Jan/2024
--
select DISTINCT
vstage.ACCEPT_RISK_RULE_COMMENT
,vstage.ACCEPTRISK
,hwam.ACCOUNT_NUMBER as ACCOUNTID 
,vstage.ACRSCORE
,vstage.ASSETEXPOSURESCORE
,vstage.BASESCORE
,vstage.BID
,vstage.CHECKTYPE
,vstage.CPE
,vstage.CVE
,vstage.CVSSV3BASESCORE
,vstage.CVSSV3TEMPORALSCORE
,vstage.CVSSV3VECTOR
,vstage.CVSSVECTOR
,hwam.DATACENTER_ID
,vstage.DESCRIPTION
,vstage.DNSNAME
,vstage.EXPLOIT_AVAILABLE
,vstage.EXPLOITEASE
,vstage.EXPLOITFRAMEWORKS
,vstage.FAMILY_ID
,vstage.FAMILY_NAME
,vstage.FAMILY_TYPE
,vstage.FIRST_SEEN
,vstage.HAS_BEEN_MITIGATED
,vstage.HOSTUNIQUENESS
,vstage.HOSTUUID
,met.instance_id as INSTANCEID 
,vstage.IP
,vstage.IPS
,vstage.KEYDRIVERS
,vstage.LAST_SEEN
,vstage.MACADDRESS
,vstage.NETBIOSNAME
,vstage.OPERATING_SYSTEM
,vstage.PATCHPUB_DATE
,vstage.PLUGIN_ID
,vstage.PLUGIN_INFO
,vstage.PLUGIN_MOD_DATE
,vstage.PLUGIN_NAME
,vstage.PLUGIN_PUB_DATE
,vstage.PLUGINTEXT
,vstage.PORT
,vstage.PROTOCOL
,vstage.RECASTRISK
,vstage.RECASTRISKRULECOMMENT
,vstage.REPOSITORY_DATAFORMAT
,vstage.REPOSITORY_DESCRIPTION
,vstage.REPOSITORY_ID
,vstage.REPOSITORY_NAME
,vstage.RISKFACTOR
,vstage.SEEALSO
,vstage.SEVERITY_DESCRIPTION
,vstage.SEVERITY_ID
,vstage.SEVERITY_NAME
,vstage.SOLUTION
,vstage.STIGSEVERITY
,vstage.SYNOPSIS
,hwam.SYSTEM_ID
,vstage.TEMPORAL_SCORE
,vstage.UNIQUENESS
,vstage.UUID
,vstage.VERSION
,vstage.VPR_SCORE
,vstage.VPRCONTEXT
,vstage.VULN_PUB_DATE 
,vstage.VULNUNIQUENESS 
,vstage.VULNUUID 
,vstage.XREF
,vstage.FILENAME
,vstage.S3_FILE_CREATE 
,vstage.SF_FILE_LOAD 
,vstage.RAW_VULNS 
from APP_TENABLE.SHARED.SEC_VW_IUSG_CUMULATIVE_VULNS_STAGING vstage

-- Added s3_file_create_date
-- Currently, repositoryid is always 1
JOIN (select replace(uuid,CHAR(10),'') as UUID, replace(accountID,CHAR(10),'') as accountID, NULLIF(replace(instanceid,CHAR(10),''),'') as instance_id
    , replace(dnsname,CHAR(10),'') as dnsname, replace(ip,CHAR(10),'') as IP, replace(repositoryid,CHAR(10),'') as repositoryid
    , s3_file_create::date as s3_file_create_date
    from APP_TENABLE.SHARED.SEC_VW_IUSG_TENABLE_PLUGIN_METADATA where ip is not null and instance_id is not null
    group by uuid, accountid, instanceid, dnsname, ip, repositoryid, s3_file_create_date) met 
    on met.repositoryid = vstage.repository_id and coalesce(NULLIF(met.dnsname,''),'ITSNULL') = coalesce(NULLIF(vstage.dnsname,''),'ITSNULL') and met.ip = vstage.ip

/* THE FOLLOWING RETURNED AN INSTANCEID THAT WAS DIFFERENT FROM THE METATDATA
LEFT OUTER JOIN (SELECT h1.instanceid,f.value::string as One_Hostname
    FROM CORE.VW_SEC_VW_HWAM_AWS_WORKAROUND_V2 h1
    join table(flatten(HOSTNAME,outer=>true)) as f
    where NULLIF(f.value::string,'') is not null
    GROUP BY h1.instanceid,f.value::string) hwamDNS on hwamDNS.One_Hostname = met.dnsname and NULLIF(met.dnsname,'') IS NOT NULL
LEFT OUTER JOIN CORE.VW_SEC_VW_HWAM_AWS_WORKAROUND_V2 hwam on hwam.instanceid = coalesce(met.instanceiD,hwamDNS.instanceiD)
*/
JOIN CORE.VW_HWAM_AWS_V2 hwam on hwam.instanceid = met.instance_id
JOIN CORE.VW_SYSTEMS dc on dc.SYSTEM_ID = hwam.DATACENTER_ID -- 240726 CR928
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = hwam.SYSTEM_ID -- 240726 CR928
WHERE met.s3_file_create_date = vstage.s3_file_create::DATE
and NULLIF(met.instance_id,'''') IS NOT NULL; -- 240726 CR928
;