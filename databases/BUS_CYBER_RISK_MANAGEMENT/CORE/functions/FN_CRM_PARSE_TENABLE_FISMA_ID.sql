CREATE OR REPLACE FUNCTION "FN_CRM_PARSE_TENABLE_FISMA_ID"("P_TENABLE_ASSET_TAGS" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
COMMENT='Parse TENABLE_ASSET_TAGS to yield FISMA_ID'
AS '

TRIM(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
(CASE CHARINDEX(''[version Primary_FISMA_ID]'',split_part(P_TENABLE_ASSET_TAGS,'','',1),1) -- First
    WHEN 0 THEN 
        CASE CHARINDEX(''[version Primary_FISMA_ID]'',split_part(P_TENABLE_ASSET_TAGS,'','',2),1) -- Second
            WHEN 0 THEN NULL
            ELSE split_part(P_TENABLE_ASSET_TAGS,'','',2)
        END
    ELSE split_part(P_TENABLE_ASSET_TAGS,'','',1)   
    END)
,''[version Primary_FISMA_ID]'',''''),''"'',''''),''['',''''),'']'',''''))



';