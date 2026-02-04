CREATE OR REPLACE FUNCTION "FN_CRM_IS_IPV4ADDRESS"("P_IPv4Address" VARCHAR(16777216))
RETURNS BOOLEAN
LANGUAGE SQL
COMMENT='Return true for a correct IPv4 format'
AS '
CASE
WHEN (P_IPv4Address = '''' or P_IPv4Address IS NULL) THEN
    FALSE
WHEN ((TRY_TO_NUMBER(split_part(P_IPv4Address,''.'',1)) IS NOT NULL) AND 
      (TRY_TO_NUMBER(split_part(P_IPv4Address,''.'',2)) IS NOT NULL) AND 
      (TRY_TO_NUMBER(split_part(P_IPv4Address,''.'',3)) IS NOT NULL) AND 
      (TRY_TO_NUMBER(split_part(P_IPv4Address,''.'',4)) IS NOT NULL)) 
THEN
    TRUE
ELSE
    FALSE
END    
';