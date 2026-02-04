CREATE OR REPLACE FUNCTION "FN_CRM_CHARACTER_SEVERITY"("P_NUMERIC_SEVERITY" NUMBER(38,0))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Return character FISMA Severity based on pre-determined numeric severity'
AS '
--
-- Created 241106
--
CASE P_NUMERIC_SEVERITY
    WHEN 4 THEN ''Critical''
    WHEN 3 THEN ''High''
    WHEN 2 THEN ''Medium''
    WHEN 1 THEN ''Low''
    ELSE ''Info''
END
';