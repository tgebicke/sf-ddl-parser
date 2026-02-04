CREATE OR REPLACE FUNCTION "FN_CRM_FORMAT_BOOLEAN"("P_BOOLEAN" BOOLEAN, "P_FORMAT" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Return varchar with format of boolean indicated by P_FORMAT. Where Yes=Yes/No, True-True/False'
AS '
     CASE
        WHEN (lower(P_FORMAT) = ''true'' and P_BOOLEAN=0) THEN ''No''
        WHEN (lower(P_FORMAT) = ''true'' and P_BOOLEAN=1) THEN ''Yes''
        WHEN (lower(P_FORMAT) = ''yes'' and P_BOOLEAN=0) THEN ''No''
        WHEN (lower(P_FORMAT) = ''yes'' and P_BOOLEAN=1) THEN ''Yes''
        ELSE P_BOOLEAN::varchar
    END
';