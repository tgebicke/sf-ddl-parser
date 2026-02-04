create or replace view VW_MFA_TEST(
	IDUID,
	PARENTCONTENTID,
	VALUE
) as
select DISTINCT ap.IDUID
--,x.*
,iou.*
FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE ap
--JOIN APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE_MFA_AUTHORIZATION_PACKAGE_X_MFA_AUTHORIZATION_PACKAGE x on x.Authorization_Package_MFA_Authorization_Package_ContentId = ap.contentid

LEFT OUTER JOIN (select distinct x.Authorization_Package_MFA_Authorization_Package_ContentId as ParentContentId,e.Value
    FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE_MFA_AUTHORIZATION_PACKAGE_X_MFA_AUTHORIZATION_PACKAGE x
    JOIN APP_CFACTS.SHARED.SEC_VW_MFA_MFA_Inherited_OU p on p.parentcontentid = x.MFA_Authorization_Package_ContentId
    JOIN APP_CFACTS.SHARED.SEC_VW_enum_MFA_Inherited_OU e on e.ID = p.value) iou on iou.ParentContentId = ap.contentid

/***************** OF INTEREST
select ap.IDUID,x.MFA_Authorization_Package_ContentId
,MFA.* 
FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE ap
JOIN APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE_MFA_AUTHORIZATION_PACKAGE_X_MFA_AUTHORIZATION_PACKAGE x on x.Authorization_Package_MFA_Authorization_Package_ContentId = ap.contentid
JOIN APP_CFACTS.SHARED.SEC_VW_MFA mfa on mfa.contentid = x.MFA_Authorization_Package_ContentId
where 
ap.iduid = '0074BAC6-7C64-452F-9991-BF844D99196C' 
and mfa.authentication_datafeed_id is not null
order by ap.IDUID,x.MFA_Authorization_Package_ContentId
****************************************************************/


/*
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Multifactor_Authentication_Options_Enabl ON  APP_CFACTS.SHARED.SEC_VW_MFA_Multifactor_Authentication_Options_Enabl.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Multifactor_Authentication_Options_Enabl on APP_CFACTS.SHARED.SEC_VW_enum_Multifactor_Authentication_Options_Enabl.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Multifactor_Authentication_Options_Enabl.Value

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_NonOrganizational_Multifactor_Authentica ON  APP_CFACTS.SHARED.SEC_VW_MFA_NonOrganizational_Multifactor_Authentica.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_NonOrganizational_Multifactor_Authentica on APP_CFACTS.SHARED.SEC_VW_enum_NonOrganizational_Multifactor_Authentica.ID = APP_CFACTS.SHARED.SEC_VW_MFA_NonOrganizational_Multifactor_Authentica.Value	

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Privileged_Multifactor_Authentication_Op ON  APP_CFACTS.SHARED.SEC_VW_MFA_Privileged_Multifactor_Authentication_Op.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Privileged_Multifactor_Authentication_Op on APP_CFACTS.SHARED.SEC_VW_enum_Privileged_Multifactor_Authentication_Op.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Privileged_Multifactor_Authentication_Op.Value	

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Privileged_NonOrganizational_Multifactor ON  APP_CFACTS.SHARED.SEC_VW_MFA_Privileged_NonOrganizational_Multifactor.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Privileged_NonOrganizational_Multifactor on APP_CFACTS.SHARED.SEC_VW_enum_Privileged_NonOrganizational_Multifactor.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Privileged_NonOrganizational_Multifactor.Value	

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Type_of_MultiFactor_Authentication_in_Us ON  APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Type_of_MultiFactor_Authentication_in_Us.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Type_of_MultiFactor_Authentication_in_Us on APP_CFACTS.SHARED.SEC_VW_enum_Type_of_MultiFactor_Authentication_in_Us.ID = APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Type_of_MultiFactor_Authentication_in_Us.Value
*/


/*
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_Authorization_Package__122_MultiFactor_Authentication ON  APP_CFACTS.SHARED.SEC_VW_Authorization_Package__122_MultiFactor_Authentication.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum__122_MultiFactor_Authentication on APP_CFACTS.SHARED.SEC_VW_enum__122_MultiFactor_Authentication.ID = APP_CFACTS.SHARED.SEC_VW_Authorization_Package__122_MultiFactor_Authentication.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_multifactor_Required ON  APP_CFACTS.SHARED.SEC_VW_Authorization_Package_multifactor_Required.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_multifactor_Required on APP_CFACTS.SHARED.SEC_VW_enum_multifactor_Required.ID = APP_CFACTS.SHARED.SEC_VW_Authorization_Package_multifactor_Required.Value	

LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Authentication_Type_Name ON  APP_CFACTS.SHARED.SEC_VW_MFA_Authentication_Type_Name.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Type_of_MultiFactor_Authentication_1 on APP_CFACTS.SHARED.SEC_VW_enum_Type_of_MultiFactor_Authentication_1.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Authentication_Type_Name.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Background_Investigation ON  APP_CFACTS.SHARED.SEC_VW_MFA_Background_Investigation.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Background_Investigation on APP_CFACTS.SHARED.SEC_VW_enum_Background_Investigation.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Background_Investigation.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU ON  APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Copy_of_SingleSignOn_SSO_OU on APP_CFACTS.SHARED.SEC_VW_enum_Copy_of_SingleSignOn_SSO_OU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU_1 ON  APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU_1.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Copy_of_SingleSignOn_SSO_OU_1 on APP_CFACTS.SHARED.SEC_VW_enum_Copy_of_SingleSignOn_SSO_OU_1.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU_1.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU_2 ON  APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU_2.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Copy_of_SingleSignOn_SSO_OU_2 on APP_CFACTS.SHARED.SEC_VW_enum_Copy_of_SingleSignOn_SSO_OU_2.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Copy_of_SingleSignOn_SSO_OU_2.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used ON  APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used on APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_NOU ON  APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_NOU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used_NOU on APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used_NOU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_NOU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_PNOU ON  APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_PNOU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used_PNOU on APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used_PNOU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_PNOU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_POU ON  APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_POU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used_POU on APP_CFACTS.SHARED.SEC_VW_enum_Entry_Point_Used_POU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Entry_Point_Used_POU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_SingleSignOn_SSO ON  APP_CFACTS.SHARED.SEC_VW_MFA_SingleSignOn_SSO.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_SingleSignOn_SSO on APP_CFACTS.SHARED.SEC_VW_enum_SingleSignOn_SSO.ID = APP_CFACTS.SHARED.SEC_VW_MFA_SingleSignOn_SSO.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_Type_of_MultiFactor_Authentication_in_Us ON  APP_CFACTS.SHARED.SEC_VW_MFA_Type_of_MultiFactor_Authentication_in_Us.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_Type_of_MultiFactor_Authentication_1 on APP_CFACTS.SHARED.SEC_VW_enum_Type_of_MultiFactor_Authentication_1.ID = APP_CFACTS.SHARED.SEC_VW_MFA_Type_of_MultiFactor_Authentication_in_Us.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_user_Interfaces ON  APP_CFACTS.SHARED.SEC_VW_MFA_user_Interfaces.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_user_Interfaces on APP_CFACTS.SHARED.SEC_VW_enum_user_Interfaces.ID = APP_CFACTS.SHARED.SEC_VW_MFA_user_Interfaces.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfaces_PNOU ON  APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfaces_PNOU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_User_Interfaces_PNOU on APP_CFACTS.SHARED.SEC_VW_enum_User_Interfaces_PNOU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfaces_PNOU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfaces_POU ON  APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfaces_POU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_User_Interfaces_POU on APP_CFACTS.SHARED.SEC_VW_enum_User_Interfaces_POU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfaces_POU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfacess_NOU ON  APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfacess_NOU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_User_Interfacess_NOU on APP_CFACTS.SHARED.SEC_VW_enum_User_Interfacess_NOU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_User_Interfacess_NOU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation ON  APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_What_stage_of_Implementation on APP_CFACTS.SHARED.SEC_VW_enum_What_stage_of_Implementation.ID = APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation_NOU ON  APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation_NOU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_What_stage_of_Implementation_NOU on APP_CFACTS.SHARED.SEC_VW_enum_What_stage_of_Implementation_NOU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation_NOU.Value	
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation_PNOU ON  APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation_PNOU.ParentContentId = ap.ContentId
LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_enum_What_stage_of_Implementation_PNOU on APP_CFACTS.SHARED.SEC_VW_enum_What_stage_of_Implementation_PNOU.ID = APP_CFACTS.SHARED.SEC_VW_MFA_What_stage_of_Implementation_PNOU.Value	
*/
WHERE ap.IDUID IS NOT NULL
--and ap.IDUID = '9009F83A-D7B8-4C11-A48A-6A7AA284F727'
ORDER BY ap.IDUID
;