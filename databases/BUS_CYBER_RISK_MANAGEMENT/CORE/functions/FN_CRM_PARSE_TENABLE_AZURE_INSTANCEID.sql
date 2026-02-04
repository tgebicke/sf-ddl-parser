CREATE OR REPLACE FUNCTION "FN_CRM_PARSE_TENABLE_AZURE_INSTANCEID"("P_TENABLE_PLUGINTEXT" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Parse TENABLE PLUGINTEXT from plugins 99171 or 99172 to yield AZURE INSTANCEID; \n99172 Microsoft Azure Instance Metadata Enumeration (Windows) -- 241021 Elliot suggested this as a possibility\n99171 Microsoft Azure Instance Metadata Enumeration (Unix) -- 241021 Elliot suggested this as a possibility\n'
AS '
CASE CHARINDEX(''- azure-instanceName:'',P_TENABLE_PLUGINTEXT,1)
    WHEN 0 THEN NULL
    ELSE TRIM(SUBSTRING(P_TENABLE_PLUGINTEXT,(POSITION(''- azure-instanceName:'',P_TENABLE_PLUGINTEXT) + 21),POSITION(''- azure-vmId'',P_TENABLE_PLUGINTEXT) - POSITION(''- azure-instanceName:'',P_TENABLE_PLUGINTEXT) - 21))
    END
   
';