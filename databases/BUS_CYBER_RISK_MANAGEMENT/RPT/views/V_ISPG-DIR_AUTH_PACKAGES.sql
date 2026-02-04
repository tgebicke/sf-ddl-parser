create or replace view "V_ISPG-DIR_AUTH_PACKAGES"(
	"Information System or Program Name",
	ACRONYM,
	"Component Acronym",
	"FIPS 199 Overall Impact Rating",
	"Authorization Decision",
	"Is this system on the HVA list for the current year?"
) COMMENT='ISPG-DIR AUTH PACKAGES'
 as
SELECT 	
ap.Authorization_Package_Name as "Information System or Program Name"
,ap.Acronym as Acronym
,ap.Component_Acronym as "Component Acronym"
,enum_FIPS_Overall.Value as "FIPS 199 Overall Impact Rating"
,eAD.Value as "Authorization Decision"
,eHVATrackingList.Value as "Is this system on the HVA list for the current year?"
FROM APP_CFACTS.SHARED.SEC_VW_Authorization_Package ap

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Recommended_Security_Category ap_FIPS_Overall on ap_FIPS_Overall.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Security_Category enum_FIPS_Overall on enum_FIPS_Overall.ID = ap_FIPS_Overall.Value

-- 230526 VW_Authorization_Package_Helper_FIPS_199_Overall_Impact_Rating_ IS NOT AVAILABLE
--LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Helper_FIPS_199_Overall_Impact_Rating_ aOverall on aOverall.ParentContentId = ap.ContentId
--LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Helper_FIPS_199_Overall_Impact_Rating_ eOverall on eOverall.ID = aOverall.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Is_this_system_on_the_HVA_tracking_list aHVATrackingList on aHVATrackingList.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_GVL_YesNo eHVATrackingList on eHVATrackingList.ID = aHVATrackingList.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Authorization_Decision AD on ap.ContentId=AD.ParentContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Authorization_Decision eAD on AD.Value=eAd.Id;