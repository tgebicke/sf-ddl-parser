CREATE OR REPLACE PROCEDURE "SP_CRM_WRITE_REPORTINGTABLES"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Populate a temp tables to improve performance for Tableau pull'
EXECUTE AS OWNER
AS '
DECLARE
Appl varchar := ''SP_CRM_WRITE_REPORTINGTABLES'';
ExceptionMsg varchar := ''Default'';
Msg varchar;
StartOfProcedure datetime := current_timestamp();
CRM_logic_exception exception (-20002, ''Raised CRM_logic_exception.'');
RECORD_COUNT number;

BEGIN
CALL CORE.SP_CRM_START_PROCEDURE (:Appl);

TRUNCATE TABLE CORE.Temp_Single_AssetInterface;

INSERT INTO CORE.Temp_Single_AssetInterface
           (DW_ASSET_ID
           ,fqdn
           ,hostname
           ,ipv4
           ,ipv6
           ,MACADDRESS
           ,netbiosname)
select 
a.DW_ASSET_ID
,iFqdn.fqdn
,iHostname.hostname
,iIpv4.ipv4
,iIpv6.ipv6
,iMac.MACADDRESS
,iNetbiosname.netbiosname
FROM Asset a
left join (select DW_ASSET_ID, Max(ID) AssetInterfaceID FROM CORE.ASSETINTERFACE_FQDN  
		WHERE fqdn IS NOT NULL group by DW_ASSET_ID) iMaxFqdn on iMaxFqdn.DW_ASSET_ID = a.DW_ASSET_ID
left join (select DW_ASSET_ID, Max(ID) AssetInterfaceID FROM CORE.ASSETINTERFACE_HOSTNAME  
		WHERE hostname IS NOT NULL group by DW_ASSET_ID) iMaxHostname on iMaxHostname.DW_ASSET_ID = a.DW_ASSET_ID
left join (select DW_ASSET_ID, Max(ID) AssetInterfaceID FROM CORE.ASSETINTERFACE_IPV4  
		WHERE ipv4 IS NOT NULL group by DW_ASSET_ID) iMaxIpv4 on iMaxIpv4.DW_ASSET_ID = a.DW_ASSET_ID
left join (select DW_ASSET_ID, Max(ID) AssetInterfaceID FROM CORE.ASSETINTERFACE_IPV6  
		WHERE ipv6 IS NOT NULL group by DW_ASSET_ID) iMaxIpv6 on iMaxIpv6.DW_ASSET_ID = a.DW_ASSET_ID
left join (select DW_ASSET_ID, Max(ID) AssetInterfaceID FROM CORE.ASSETINTERFACE_MACADDRESS  
		WHERE MACADDRESS IS NOT NULL group by DW_ASSET_ID) iMaxMac on iMaxMac.DW_ASSET_ID = a.DW_ASSET_ID
left join (select DW_ASSET_ID, Max(ID) AssetInterfaceID FROM CORE.ASSETINTERFACE_NETBIOSNAME  
		WHERE netbiosname IS NOT NULL group by DW_ASSET_ID) iMaxNetbiosname on iMaxNetbiosname.DW_ASSET_ID = a.DW_ASSET_ID

left join (select ID AssetInterfaceID, fqdn FROM CORE.ASSETINTERFACE_FQDN ) iFqdn on iFqdn.AssetInterfaceID = iMaxFqdn.AssetInterfaceID
left join (select ID AssetInterfaceID, hostname FROM CORE.ASSETINTERFACE_HOSTNAME ) iHostname on iHostname.AssetInterfaceID = iMaxHostname.AssetInterfaceID
left join (select ID AssetInterfaceID, ipv4 FROM CORE.ASSETINTERFACE_IPV4 ) iIpv4 on iIpv4.AssetInterfaceID = iMaxIpv4.AssetInterfaceID
left join (select ID AssetInterfaceID, ipv6 FROM CORE.ASSETINTERFACE_IPV6 ) iIpv6 on iIpv6.AssetInterfaceID = iMaxIpv6.AssetInterfaceID
left join (select ID AssetInterfaceID, MACADDRESS FROM CORE.ASSETINTERFACE_MACADDRESS ) iMac on iMac.AssetInterfaceID = iMaxMac.AssetInterfaceID
left join (select ID AssetInterfaceID, netbiosname FROM CORE.ASSETINTERFACE_NETBIOSNAME ) iNetbiosname on iNetbiosname.AssetInterfaceID = iMaxNetbiosname.AssetInterfaceID

WHERE a.Is_Applicable = 1;

RECORD_COUNT := SQLROWCOUNT;
Msg := ''Temp_Single_AssetInterface rows written='' || RECORD_COUNT::varchar;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); 

TRUNCATE TABLE rpt.AssetDetail;

INSERT INTO rpt.AssetDetail
           (filter
           ,SYSTEM_ID
           ,DATACENTER_ID
           ,ID
           ,DW_VUL_ID
           ,cve
           ,daysSinceDiscovery
           ,exploitavailable
           ,firstseen
           ,fismaseverity
           ,lastfound
           ,mitigationstatus
           ,Snapshot_ID
           ,BODDueDate
           ,dateCreated
           ,datemitigated
           ,DeletionReason
           ,Acronym
           ,Acr_Alias
           ,Component_Acronym
           ,is_bod
           ,rankk
           ,refresh_date
           ,solution
           ,familyname
           ,HVAStatus
           ,MEFStatus
           ,Is_MarketPlace
           ,signature
           ,pluginid
           ,data_center_name
           ,DW_ASSET_ID
           ,computer_type
           ,os
           ,bios_guid
           ,source_tool
           ,environment
           ,asset_id_tattoo
           ,os_version
           ,TenableUUID
           ,DeviceType
           ,fqdn
           ,hostname
           ,ipv4
           ,ipv6
           ,MAC -- MACADDRESS
           ,netbiosname
           ,VulnRiskTolerance
           ,cvss2basescore
           ,OATO_Category
           ,Sensor_firstseen
           ,Sensor_lastfound
           ,cvss3basescore
           --,dw_asset_id
           --,datacenter_id_derived
           ,AWS_accountIds
           ,TLC_Phase
           ,CLOUD_ACCOUNT_ID -- 241125 CR1038
           )
select 1 as filter
,a.SYSTEM_ID,a.DATACENTER_ID,vm.DW_VUL_ID as ID,vm.DW_VUL_ID
,vm.cve,vm.daysSinceDiscovery,vm.exploitavailable,vm.firstseen,vm.fismaseverity
,vm.lastfound,vm.mitigationstatus
,1 as Snapshot_ID
,vm.BODDueDate
,vm.INSERT_DATE -- dateCreated
,vm.datemitigated
,null as DeletionReason
,s.Acronym
,substring(s.Acronym, 1, 1) || ''***'' as Acr_Alias
,s.COMPONENT_ACRONYM
,vm.IS_KEV as is_bod
,1 as rankk
,CURRENT_TIMESTAMP() as refresh_date
,p.solution
,p.FAMILY_NAME as familyname
,s.HVAStatus
,s.MEFStatus
,s.Is_MarketPlace
,p.synopsis as signature
,p.PLUGIN_ID
,a.DATACENTER_ACRONYM as data_center_name
,vm.DW_ASSET_ID,a.computer_type,a.os,a.bios_guid,a.SOURCE_TOOL_CREATE -- source_tool
,a.environment,a.asset_id_tattoo,a.os_version,a.TenableUUID,a.DeviceType
,aic.fqdn 
,aic.hostname 
,aic.ipv4 
,aic.ipv6 
,aic.MACADDRESS 
,aic.netbiosname 
,a.VulnRiskTolerance
,vm.CVSSV2BASESCORE
,s.OATO_Category
,vm.firstseen as Sensor_firstseen -- a separate field called Sensor_firstseen no longer exists. It was only a diagnostic field in legacy
,vm.lastfound as Sensor_lastfound -- a separate field called Sensor_lastfound no longer exists. It was only a diagnostic field in legacy
,vm.CVSSV3BASESCORE
--,a.dw_asset_id 
--,a.DATACENTER_ID as DATACENTER_ID_DERIVED -- dc.CFACTS_UID as datacenter_id_derived
,s.AWS_ACCOUNTIDS as AWS_accountId
,s.TLC_Phase
,a.CLOUD_ACCOUNT_ID -- 241125 CR1038
from CORE.VW_Assets a  
JOIN CORE.VW_SYSTEMS s on s.SYSTEM_ID = a.SYSTEM_ID
JOIN CORE.VW_VULMASTER vm on vm.dw_asset_id = a.dw_asset_id
left outer join (select DW_VUL_ID,max(ID) as MAX_VULPLUGIN_ID FROM CORE.VULPLUGIN group by DW_VUL_ID) plugs on plugs.DW_VUL_ID = vm.dw_vul_id
left outer join CORE.VULPLUGIN p on p.ID = plugs.MAX_VULPLUGIN_ID
left outer join CORE.Temp_Single_AssetInterface aic on aic.DW_ASSET_ID = a.dw_asset_id;

RECORD_COUNT := SQLROWCOUNT;
Msg := ''rpt.AssetDetail rows written='' || RECORD_COUNT::varchar;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); 

TRUNCATE TABLE RPT.Temp_Vuln_FV_Rolling60Days;

INSERT INTO RPT.Temp_Vuln_FV_Rolling60Days
select * FROM CORE.VW_VULN_ROLLING60DAYS;

RECORD_COUNT := SQLROWCOUNT;
Msg := ''rpt.Temp_Vuln_FV_Rolling60Days rows written='' || RECORD_COUNT::varchar;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg); 

TRUNCATE TABLE RPT.Temp_Vuln_Trending;

INSERT INTO RPT.Temp_Vuln_Trending
select * FROM CORE.VW_VULN_DASHBOARD_TRENDING;

RECORD_COUNT := SQLROWCOUNT;
Msg := ''rpt.Temp_Vuln_Trending rows written='' || RECORD_COUNT::varchar;
CALL CORE.SP_CRM_WRITE_MSGLOG (:Appl,:Msg);

CALL CORE.SP_CRM_END_PROCEDURE (:Appl);

return ''Success'';

EXCEPTION
  when statement_error then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''Statement_Error'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
  when CRM_logic_exception then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''CRM_logic_exception'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
  when other then
    insert into CORE.ALERTLOG (APPL,CUSTOM_ERRMSG,ERRTYPE,SQLCODE,SQLERRM,SQLSTATE) VALUES(:APPL,:ExceptionMsg,''Other error'',:SQLCODE,:SQLERRM,:SQLSTATE);
    raise;
END
';