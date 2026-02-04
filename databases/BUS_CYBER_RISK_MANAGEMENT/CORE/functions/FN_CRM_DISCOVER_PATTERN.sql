CREATE OR REPLACE FUNCTION "FN_CRM_DISCOVER_PATTERN"("P_STRING" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Replace alphas and numbers with $ to yield adata pattern'
AS '
--
-- Replace alphas and numbers with $
-- remaining characters represent a format pattern when special
-- characters are included in the string
--
REGEXP_REPLACE(upper(P_STRING),''[A-Z0-9]+'',''$'')  
  
';