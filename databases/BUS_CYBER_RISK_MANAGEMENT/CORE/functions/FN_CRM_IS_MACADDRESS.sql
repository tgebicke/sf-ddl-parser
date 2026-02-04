CREATE OR REPLACE FUNCTION "FN_CRM_IS_MACADDRESS"("P_MACADDRESS" VARCHAR(16777216))
RETURNS BOOLEAN
LANGUAGE SQL
COMMENT='Return true for a valid MACADDRESS format'
AS '
CASE
WHEN (P_MACADDRESS = '''' or P_MACADDRESS IS NULL) THEN
    FALSE
WHEN (P_MACADDRESS REGEXP  ''[0-9,a-f,A-F]{2}:[0-9,a-f,A-F]{2}:[0-9,a-f,A-F]{2}:[0-9,a-f,A-F]{2}:[0-9,a-f,A-F]{2}:[0-9,a-f,A-F]{2}''
   or P_MACADDRESS REGEXP  ''[0-9,a-f,A-F]{2}-[0-9,a-f,A-F]{2}-[0-9,a-f,A-F]{2}-[0-9,a-f,A-F]{2}-[0-9,a-f,A-F]{2}-[0-9,a-f,A-F]{2}''
   or P_MACADDRESS REGEXP  ''[0-9,a-f,A-F]{2} [0-9,a-f,A-F]{2} [0-9,a-f,A-F]{2} [0-9,a-f,A-F]{2} [0-9,a-f,A-F]{2} [0-9,a-f,A-F]{2}''
   or P_MACADDRESS REGEXP  ''[0-9,a-f,A-F]{3}.[0-9,a-f,A-F]{3}.[0-9,a-f,A-F]{3}.[0-9,a-f,A-F]{3}''  -- nor really valid, but present in DB
   or P_MACADDRESS REGEXP  ''[0-9,a-f,A-F]{12}'') THEN
    TRUE
ELSE
    FALSE
END    
';