CREATE OR REPLACE FUNCTION "FN_CRM_GET_ROWDISPOSITION_CLEANED"()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Return string indicating record has been cleaned and is ready for further processing'
AS '
''Cleaned''
';