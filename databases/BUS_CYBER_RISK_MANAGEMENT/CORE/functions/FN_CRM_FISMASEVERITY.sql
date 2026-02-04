CREATE OR REPLACE FUNCTION "FN_CRM_FISMASEVERITY"("P_CVSS_VERSION" VARCHAR(16777216), "P_CVSS" NUMBER(38,1))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Return character FISMA Severity appropriate to CVSS_VERSION'
AS '
CASE P_CVSS_VERSION
    WHEN ''3.0'' THEN
    CASE 
        WHEN P_CVSS BETWEEN 9.0 AND 10.0 THEN ''Critical''
        WHEN P_CVSS BETWEEN 7.0 AND 8.9 THEN ''High''
        WHEN P_CVSS BETWEEN 4.0 AND 6.9 THEN ''Medium''
        WHEN P_CVSS BETWEEN 0.1 AND 3.9 THEN ''Low''
        WHEN P_CVSS = 0.0 THEN ''Informational''
        ELSE ''Unknown''
    END
    WHEN ''2.0'' THEN
    CASE 
        WHEN P_CVSS = 10.0 THEN ''Critical''
        WHEN P_CVSS BETWEEN 7.0 AND 9.9 THEN ''High''
        WHEN P_CVSS BETWEEN 4.0 AND 6.9 THEN ''Medium''
        WHEN P_CVSS BETWEEN 0.1 AND 3.9 THEN ''Low''
        WHEN P_CVSS = 0.0 THEN ''Informational''
        ELSE ''Unknown''
    END
        WHEN ''0'' THEN -- Tenable integer severity number
    CASE 
        WHEN P_CVSS = 4 THEN ''Critical''
        WHEN P_CVSS = 3 THEN ''High''
        WHEN P_CVSS = 2 THEN ''Medium''
        WHEN P_CVSS = 1 THEN ''Low''
        WHEN P_CVSS = 0 THEN ''Informational''
        ELSE ''Unknown''
    END
END
';