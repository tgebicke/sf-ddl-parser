create or replace view VW_CONFIGURATION_COMPLIANCE(
	COMPONENT_ACRONYM,
	DATACENTER_ACRONYM,
	SYSTEM_ACRONYM,
	CONTROL_SET_VERSION_NUMBER_SYSTEM_PROVID,
	DW_ASSET_ID,
	ALLOCATION_STATUS,
	AUDIT_FILE_NAME,
	CHECK_ID,
	CHECK_NAME,
	COMPLIANCE_STATUS,
	CONTROL_NAME,
	CONTROL_ELEMENT,
	DAYSSINCEDISCOVERY,
	FINDING_DESCRIPTION,
	FINDING_ID,
	FIRST_SEEN,
	FQDN,
	HOSTNAME,
	IA_CONTROLS,
	IPV4,
	IPV6,
	IS_TENABLE_CREDENTIALED_SCAN,
	LAST_SEEN,
	MACADDRESS,
	OS,
	POLICY,
	RULE_ID,
	SERVER_TYPE,
	SEVERITY,
	SEVERITY_NAME,
	SOURCE_ID,
	SOURCE_TOOL,
	DATACENTER_ID,
	SYSTEM_ID,
	POLICY_800_53,
	IA_CONTROLS_800_53,
	POLICY_800_53R5,
	IA_CONTROLS_800_53R5
) as
select
s.COMPONENT_ACRONYM
,a.DATACENTER_ACRONYM
,s.ACRONYM as SYSTEM_ACRONYM
,s.CONTROL_SET_VERSION_NUMBER_SYSTEM_PROVID
,comp.dw_asset_id
,aloc.allocation_status
,comp.Audit_File_Name
,comp.Check_ID
,comp.Check_Name
,comp.Compliance_Status
,aloc.control_name
,aloc.control_element
,comp.DAYSSINCEDISCOVERY
,comp.Finding_Description
,comp.Finding_ID
,comp.FIRST_SEEN
,a.FQDN
,a.HOSTNAME
,comp.IA_CONTROLS
,a.ipv4
,a.ipv6
,a.IS_TENABLE_CREDENTIALED_SCAN
,comp.LAST_SEEN as LAST_SEEN
,a.macaddress
,a.os
,comp.POLICY as POLICY
,comp.Rule_ID
,CASE upper(substring(CHECK_NAME,1,1))
        when 'W' then 
            CASE upper(SPLIT_PART(CHECK_NAME,'-',2))
                when 'DC' then 'DC'
                when 'MS' then 'MS'
                Else NULL
            End
        Else NULL
End as Server_Type
,comp.Severity

,case coalesce(upper(comp.Severity),'ITSNULL')
    when 'I' then 'High'
    when 'II' then 'Medium'
    when 'III' then 'Low'
    Else 'Unknown'
End as Severity_Name

,'TBD' as Source_ID
,'Tenable' as Source_Tool
,a.DATACENTER_ID
,a.SYSTEM_ID
,comp.POLICY_800_53
,comp.IA_CONTROLS_800_53
,comp.POLICY_800_53R5
,comp.IA_CONTROLS_800_53R5
FROM core.VW_SYSTEMS s
join core.vw_assets a on a.system_id = s.system_id
--
-- THE FOLLOWING SHOULD BE LEFT OUTER 
--
JOIN (select
r.dw_asset_id

,position('<cm:compliance-audit-file>',r.plugintext,1) as CompAuditFileStart
,position('</cm:compliance-audit-file>',r.plugintext,1) as CompAuditFileEnd
,substring(r.plugintext,((CompAuditFileStart) + 26),(CompAuditFileEnd - CompAuditFileStart - 26)) as Audit_File_Name

,position('<cm:compliance-check-name>',r.plugintext,1) as CompCheckNameStart
,position('</cm:compliance-check-name>',r.plugintext,1) as CompCheckNameEnd
,substring(r.plugintext,((CompCheckNameStart) + 26),(CompCheckNameEnd - CompCheckNameStart - 26)) as Check_Name

,case POSITION(' - ',Check_Name,1)
    WHEN 0 then SUBSTRING(split_part(Check_Name,' ',1),1,22)
    Else SUBSTRING(split_part(Check_Name,' - ',1),1,22)      
End as Check_ID

,position('<cm:compliance-result>',r.plugintext,1) as CompResultStart
,position('</cm:compliance-result>',r.plugintext,1) as CompResultEnd
,substring(r.plugintext,((CompResultStart) + 22),(CompResultEnd - CompResultStart - 22)) as Compliance_Status

,position('<cm:compliance-info>',r.plugintext,1) as CompInfoStart
,position('</cm:compliance-info>',r.plugintext,1) as CompInfoEnd
,substring(r.plugintext,((CompInfoStart) + 20),(CompInfoEnd - CompInfoStart - 20)) as Finding_Description

,position('<cm:compliance-reference>',r.plugintext,1) as CompRefStart
,position('</cm:compliance-reference>',r.plugintext,1) as CompRefEnd
,substring(r.plugintext,((CompRefStart) + 25),(CompRefEnd - CompRefStart - 25)) as Compliance_Reference_String
,STRTOK_TO_ARRAY(Compliance_Reference_String,',|') as Compliance_Reference_Array

,DATEDIFF(day,r.FIRST_SEEN,r.LAST_SEEN) as DAYSSINCEDISCOVERY
,r.FIRST_SEEN
,r.LAST_SEEN

,REPLACE(GET(Compliance_Reference_Array,(array_position('CAT'::variant,Compliance_Reference_Array) + 1)),'"','') as Severity
,REPLACE(GET(Compliance_Reference_Array,(array_position('Vuln-ID'::variant,Compliance_Reference_Array) + 1)),'"','') as Finding_ID
,REPLACE(GET(Compliance_Reference_Array,(array_position('Rule-ID'::variant,Compliance_Reference_Array) + 1)),'"','') as Rule_ID
,GET(Compliance_Reference_Array,array_position('800-53'::variant,Compliance_Reference_Array))::varchar as POLICY_800_53
,GET(Compliance_Reference_Array,array_position('800-53r5'::variant,Compliance_Reference_Array))::varchar as POLICY_800_53R5
,REPLACE(GET(Compliance_Reference_Array,(array_position('800-53'::variant,Compliance_Reference_Array) + 1)),'.','')::varchar as IA_CONTROLS_800_53
,REPLACE(GET(Compliance_Reference_Array,(array_position('800-53r5'::variant,Compliance_Reference_Array) + 1)),'.','')::varchar as IA_CONTROLS_800_53R5
,REPLACE(GET(Compliance_Reference_Array,(array_position('DISA_Benchmark'::variant,Compliance_Reference_Array) + 1)),'"','') as DISA_Benchmark
,coalesce(POLICY_800_53R5,POLICY_800_53) as POLICY -- Favor r5
,coalesce(IA_CONTROLS_800_53R5,IA_CONTROLS_800_53) as IA_CONTROLS -- Favor r5
FROM core.SNAPSHOT_IDS snap
JOIN core.RAW_TENABLE_VUL r on r.SNAPSHOT_ID = snap.SNAPSHOT_ID
where snap.snapshot_date::date = current_date()
and r.plugin_id NOT IN ('1218405','1221295') -- In house plugins for retrieving 
and Check_Name not in ('Check for Empty FISMA Tattoo files.','Print out FISMA registry keys.') -- Filtering by plugin_id did not eliminate all the In-house written plugins
and POLICY LIKE '%800-53%'
and r.family_type = 'compliance' 
--and position('<cm:compliance-reference>',plugintext,1) > 0
) comp on comp.dw_asset_id = a.dw_asset_id
left outer join core.ALLOCATEDCONTROL aloc on aloc.system_id = s.system_id and aloc.CONTROL_ELEMENT_NUMBER = comp.ia_controls
;