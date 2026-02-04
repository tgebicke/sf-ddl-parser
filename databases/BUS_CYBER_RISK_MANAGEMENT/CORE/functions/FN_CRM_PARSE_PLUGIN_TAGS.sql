CREATE OR REPLACE FUNCTION "FN_CRM_PARSE_PLUGIN_TAGS"("P_TENABLE_PLUGINTEXT" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Parse Tenable plugintext to yield entire tag string for Plugin_id 1221295 (Windows), Plugin_id 1218405 (Linux)'
AS ' 
/*

NOTE: CHAR(10) is a line-feed
NOTE: The order in which Asset_ID and Primary_FISMA_ID appear can vary


WINDOWS (plugin_id = 1221295)

<cm:compliance-check-name>Print out FISMA registry keys.</cm:compliance-check-name>
<cm:compliance-actual-value>The Asset_ID is TheActualValue
The Primary_FISMA_ID is TheActualValue</cm:compliance-actual-value>

LINUX (plugin_id = 1218405)

<cm:compliance-check-name>Check for Empty FISMA Tattoo files.</cm:compliance-check-name>
<cm:compliance-actual-value>The command returned : 

/var/CMS/FISMA/Asset_ID/TheActualValue
/var/CMS/FISMA/Primary_FISMA_ID/TheActualValue</cm:compliance-actual-value>
*/

TRIM(
RTRIM(
NULLIF(
REPLACE(
substring(P_TENABLE_PLUGINTEXT,(charindex(''<cm:compliance-actual-value>'',P_TENABLE_PLUGINTEXT,1) + 28)
,(charindex(''</cm:compliance-actual-value>'',P_TENABLE_PLUGINTEXT,1) - charindex(''<cm:compliance-actual-value>'',P_TENABLE_PLUGINTEXT,1) - 28))
,(''The command returned : '' || char(10) || char(10)),''''
)
,'''')
,CHAR(10))
)

-- POSSIBLE USE FOR RESULT e.g. PASSED/ERROR
-- || '';'' || substring(P_TENABLE_PLUGINTEXT,(charindex(''<cm:compliance-result>'',P_TENABLE_PLUGINTEXT,1) + 22)
--,(charindex(''</cm:compliance-result>'',P_TENABLE_PLUGINTEXT,1) - charindex(''<cm:compliance-result>'',P_TENABLE_PLUGINTEXT,1) - 22))
--



';