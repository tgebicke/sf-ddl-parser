CREATE OR REPLACE FUNCTION "FN_CRM_NUMERIC_SEVERITY"("P_CVSS_VERSION" VARCHAR(16777216), "P_CVSS" VARCHAR(16777216))
RETURNS NUMBER(38,0)
LANGUAGE SQL
COMMENT='Return number of FISMA Severity appropriate to CVSS_VERSION and CVSS'
AS '
--
-- Created 241106
-- Upstream views define P_CVSS as varchar and as such some rows have null or empty-string in the field
--
CASE P_CVSS_VERSION
    WHEN ''3.0'' THEN
    IFF(coalesce(nullif(P_CVSS,''''),0) >= 9.0,4,IFF(coalesce(nullif(P_CVSS,''''),0) >= 7.0,3,IFF(coalesce(nullif(P_CVSS,''''),0) >= 4.0,2,IFF(coalesce(nullif(P_CVSS,''''),0) >= 0.1,1,0))))
    WHEN ''2.0'' THEN
    IFF(coalesce(nullif(P_CVSS,''''),0) = 10.0,4,IFF(coalesce(nullif(P_CVSS,''''),0) >= 7.0,3,IFF(coalesce(nullif(P_CVSS,''''),0) >= 4.0,2,IFF(coalesce(nullif(P_CVSS,''''),0) >= 0.1,1,0))))
    ELSE 0
END
';