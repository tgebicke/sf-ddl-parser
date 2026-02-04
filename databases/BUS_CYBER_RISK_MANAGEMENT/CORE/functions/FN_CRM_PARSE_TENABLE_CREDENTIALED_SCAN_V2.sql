CREATE OR REPLACE FUNCTION "FN_CRM_PARSE_TENABLE_CREDENTIALED_SCAN_V2"("P_TENABLE_PLUGINTEXT" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Parse TENABLE PLUGINTEXT to yield CREDENTIALED_SCAN'
AS '
--
-- 241112 CR1028
-- Use Credentialed Checks parameter instead of Credentialed_Scan.
-- Elliot and Will confirmed that this (new) parameter is more consistent accross Nessus versions and OS.
-- The results can contain a qualified answer indicating how it was credential scanned but we are only interested in true or false

--
-- 123456789012345678901
-- Credentialed Checks :
--
-- Found the following distinct values among three months of data:
-- yes
-- noP
-- no 
--
CASE POSITION(''Credentialed checks :'',P_TENABLE_PLUGINTEXT)
    WHEN 0 THEN ''0''
    ELSE case SUBSTRING(P_TENABLE_PLUGINTEXT,(POSITION(''Credentialed checks :'',P_TENABLE_PLUGINTEXT) + 22),3)
        when ''yes'' then ''1''
        Else ''0''
        End
    END
';