CREATE OR REPLACE FUNCTION "FN_CRM_IS_VALID_ASSET_ID_TATTOO"("P_ASSET_ID_TATTOO" VARCHAR(16777216))
RETURNS BOOLEAN
LANGUAGE SQL
COMMENT='Return true for a valid ASSET_ID_TATTOO format'
AS '
CASE
WHEN (P_ASSET_ID_TATTOO = '''' or P_ASSET_ID_TATTOO IS NULL) THEN
    FALSE
WHEN (P_ASSET_ID_TATTOO IN (''User-defined error: not set''
				,''User-defined error: missing folder''
				,''*.sharepointapps.cms.gov''			
				,''*.sharepointapps.cms.cmstest''
				,''*.sharepointapps.cms.cmsval''
				,''~uneval''
				,''~unk''
				,''<not reported>''
				,''Singular expression refers to non-unique object.''
				,''<not reported>''
				,''Fixlet not found error evaluating property.''
                ,''missing folder'' -- 230731
				,''NULL''
				,''Property not found.''
				,''Unknown error while evaluating property.''
				,''User-defined error: missing folder''
				,''User-defined error: not set''
                ,''/var/CMS/FISMA/Asset_ID'' -- 240827 CR-TBD new
				)
        or P_ASSET_ID_TATTOO LIKE ''%counteract_svc_act%password:%''
	    or P_ASSET_ID_TATTOO LIKE ''%error while evaluating property%''
	    or upper(P_ASSET_ID_TATTOO) LIKE ''%NO SUCH FILE OR DIRECTORY%'' -- 240827 CR-TBD chg to upper
	    or upper(P_ASSET_ID_TATTOO) LIKE ''%PERMISSION DENIED%'' -- 240827 CR-TBD chg to upper
        or upper(P_ASSET_ID_TATTOO) LIKE ''%OPERATION NOT PERMITTED%'' -- 240827 CR-TBD new
        or upper(P_ASSET_ID_TATTOO) LIKE ''%NOT FOUND%'' -- 240827 CR-TBD new
      )
THEN
    FALSE
ELSE
    TRUE
END    
';