CREATE OR REPLACE FUNCTION "FN_CRM_CLEAN_FORESCOUT_STRING"("P_Instring" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Remove unwanted strings/characters from a Forescout varchar field.'
AS '
     CASE
        WHEN (P_Instring IS NULL) THEN NULL
        WHEN (P_Instring = '''') THEN NULL -- empty strings
        WHEN (P_Instring = ''default_cpe'') THEN NULL
        WHEN (P_Instring = ''Irresolvable'') THEN NULL
        WHEN (P_Instring = ''None'') THEN NULL
        WHEN (P_Instring = ''Unknown'') THEN NULL
        ELSE TRIM(P_Instring)
    END
';