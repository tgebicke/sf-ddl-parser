CREATE OR REPLACE FUNCTION "FN_CRM_CLEANSTRING_CHRIS"("P_InString" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Remove unwanted characters from a varchar field.  DO NOT USE FOR dateTime FIELDS BECAUSE RESOLUTION IS REDUCED. e.g. seconds'
AS '
     CASE
        -- empty strings
        WHEN (P_InString IS NULL) THEN NULL
        WHEN (LEN(P_InString) = 0) THEN NULL
        WHEN (P_InString = ''~NoData~'') THEN NULL
        
        -- remove all non-ASCII charaters and any leading spaces, single quotes, or double quotes
        ELSE LTRIM(LTRIM(LTRIM(RTRIM(RTRIM(RTRIM(regexp_replace(P_InString, ''[^[:ascii:]]'', ''$FOUND''), '' ''), CHAR(34)), CHAR(39)), ''  ''), CHAR(34)), CHAR(39))
    END
';