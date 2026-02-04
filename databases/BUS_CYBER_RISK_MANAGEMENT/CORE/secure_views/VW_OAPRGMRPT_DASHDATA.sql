create or replace secure view VW_OAPRGMRPT_DASHDATA(
	ACRONYM,
	"OA Ready",
	OA_STATUS,
	"ResidualRisk",
	"TotalAssets",
	"Asset Risk Tolerance",
	OATO_CATEGORY,
	HVASTATUS,
	MEFSTATUS,
	FIPS_199_OVERALL_IMPACT_RATING,
	PII_PHI,
	FINANCIAL_SYSTEM,
	COMPONENT,
	"DevSecOPS / CSM",
	GROUP_ACRONYM,
	IN_CMS_CLOUD,
	LAST_ACT_DATE,
	LAST_ACT_SCA_FINAL_REPORT_DATE,
	LAST_PENTEST_DATE,
	IS_SECURITYHUB_ENABLED,
	SYSTEM,
	TLC_PHASE,
	"Vuln Risk Tolerance",
	"Resiliency Score",
	"Is_MarketPlace"
) COMMENT='Gather system info directly from CFACTS table and same view on rpt schema is used for OA dashbord'
 as(
WITH ResiliencyScoreCte as (select a.TRACKING_ID,
          SUM(IFF(eRiskLevel.Value='Critical',45,IFF(eRiskLevel.Value='High',30,IFF(eRiskLevel.Value='Moderate',15,IFF(eRiskLevel.Value='Low',10,1))))) as ResiliencyScore										
          FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE a												
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMS_AUTHORIZATION_PACKAGE_X_AUTHORIZATION_PACKAGE_POAMS as pa on a.ContentId=pa.Authorization_Package_POAMs_ContentId												
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMS as p ON p.ContentId=pa.POAMs_Authorization_Package_ContentId												
          LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMS_WEAKNESS_RISK_LEVEL_1 as pRiskLevel on pRiskLevel.ParentContentId = p.ContentId												
          LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_ENUM_RISK_LEVEL_1 as eRiskLevel on eRiskLevel.ID = pRiskLevel.Value
          LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_POAMS_OVERALL_STATUS as ps ON ps.ParentContentId=p.ContentId												
          LEFT OUTER JOIN APP_CFACTS.SHARED.SEC_VW_ENUM_STATUS_9 as eps ON eps.Id=ps.Value						
          where eps.Value in ('Delayed', 'Ongoing', 'Draft') GROUP BY a.TRACKING_ID),
    CurAWSAssetTotalCte as (select count(distinct VW.INSTANCEID) awsAssetTotal, VW.PRIMARY_FISMA_ID_DERIVED
                              from APP_CDM.SHARED.SEC_VW_HWAM_AWS VW
                              where VW.InstanceStatus not like '%stop%'
                              group by VW.PRIMARY_FISMA_ID_DERIVED),
    LastMonthAssetTotalCte as (select SS.PRIMARY_FISMA_ID, count(distinct SS.INSTANCEID) as lstMnthTotCnt
           from CORE.OATO_HWAM_MONTHLY_DATA SS
           where SS.InstanceStatus not like '%stop%'
           and SS.MONTH_END_DATE=last_day(dateadd('MONTH', -1, current_date()),'month')
           GROUP BY SS.PRIMARY_FISMA_ID),
    MefStatusCte as (select distinct ap.ContentId, listagg(e_ap_MEF.value,',') as mefstatus
          FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE ap
          left join APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE_MISSION_ESSENTIAL_FUNCTIONS_ ap_mef on ap_mef.ParentContentId=ap.ContentId
          left join APP_CFACTS.SHARED.SEC_VW_ENUM_MISSION_ESSENTIAL_FUNCTIONS_ e_ap_MEF on e_ap_MEF.Id=ap_mef.value
          group by ap.ContentId),
    PackageTypeCte as (select ap.ContentId, e_ap_pt.Value as packagetype
          FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE ap
          left join APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE_PACKAGE_TYPE ap_pt on ap_pt.ParentContentId = ap.ContentId
          left join APP_CFACTS.SHARED.SEC_VW_ENUM_PACKAGE_TYPE e_ap_pt ON e_ap_pt.Id = ap_pt.value
          group by ap.ContentId, e_ap_pt.Value),		  
    InfoSysTypeCte as (select ap.ContentId, e_ap_ist.Value as infosystype
          FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE ap
          left join APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE_INFORMATION_SYSTEM_TYPE ap_ist on ap_ist.ParentContentId = ap.ContentId
          left join APP_CFACTS.SHARED.SEC_VW_ENUM_INFORMATION_SYSTEM_TYPE e_ap_ist on e_ap_ist.Id = ap_ist.value
          group by ap.ContentId, e_ap_ist.Value),
	TotalPOAMSRBDCte as (select ap.ContentId, count(*) as residualRisk
          FROM APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE ap 
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMS_AUTHORIZATION_PACKAGE_X_AUTHORIZATION_PACKAGE_POAMS pa ON pa.Authorization_Package_POAMs_ContentId=ap.ContentId
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMS p ON p.ContentId=pa.POAMs_Authorization_Package_ContentId
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_POAMS_RISK_ACCEPTANCE_RBD_POAMS_X_RISK_ACCEPTANCE_RBD_POAMS pr ON p.ContentId=pr.POAMs_Risk_Acceptance_RBD_POAMs_ContentId
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_RISK_ACCEPTANCE_RBD r on r.ContentId=pr.Risk_Acceptance_RBD_POAMs_ContentId
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_RISK_ACCEPTANCE_RBD_OVERALL_STATUS rs ON rs.ParentContentId=r.ContentId
          INNER JOIN APP_CFACTS.SHARED.SEC_VW_ENUM_RBD_OVERALL_STATUS ers on rs.Value=ers.Id
          Where ers.Value='Approved with Signatures'
          group by ap.ContentId),    
    GroupAcronymCte as (SELECT ap.Acronym, g.Group_Acronym as groupacronym
          FROM APP_CFACTS.SHARED.SEC_VW_Authorization_Package ap
          JOIN APP_CFACTS.SHARED.SEC_VW_Division_Authorization_Packages_x_Authorization_Package_Office dapcx on dapcx.Authorization_Package_Office_ContentId = ap.ContentId
          JOIN APP_CFACTS.SHARED.SEC_VW_Division div on div.ContentId = dapcx.Division_Authorization_Packages_ContentId
          JOIN APP_CFACTS.SHARED.SEC_VW_Group_Division_x_Division_Group gdx on gdx.Division_Group_ContentId = div.ContentId
          JOIN APP_CFACTS.SHARED.SEC_VW_group g on g.ContentId = gdx.Group_Division_ContentId
          JOIN APP_CFACTS.SHARED.SEC_VW_Component c on c.Component_Acronym = ap.Component_Acronym),
    OACategoryCte as (select ap.Acronym Acronym,
                    (IFF(((ehvalst.value IS NOT NULL and ehvalst.value = 'Yes')
                    or (Len(IFF(contains(mefstatusTbl.mefstatus, 'N/A'),'',(iff(len(mefstatusTbl.mefstatus)>0,'Yes','')))) > 0)
                    or (ersc.value IS NOT NULL and ersc.value = 'High')), 3,
                    IFF((((PIIMainEnum.value IS NOT NULL AND PIIMainEnum.value='Yes') OR 
                          (PHIMainEnum.value IS NOT NULL AND PHIMainEnum.value='Yes'))
                  or (efs.value IS NOT NULL and efs.value = 'Yes')
                  or (ersc.value IS NOT NULL and ersc.value = 'Moderate')),2,1))) as OATO_Category
         from APP_CFACTS.SHARED.SEC_VW_Authorization_Package as ap
         left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Recommended_Security_Category as aprsc on aprsc.ParentContentId=ap.ContentId
         left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Is_this_system_on_the_HVA_tracking_list as aphvalst on aphvalst.ParentContentId=ap.ContentId
         left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Financial_System as apfs on apfs.ParentContentId=ap.ContentId 
         left join APP_CFACTS.SHARED.SEC_VW_enum_Security_Category as ersc on ersc.Id = aprsc.value 
         left join APP_CFACTS.SHARED.SEC_VW_enum_GVL_YesNo as ehvalst on ehvalst.Id = aphvalst.value
         left join MefStatusCte as mefStatusTbl on mefStatusTbl.contentId=ap.contentId
         LEFT JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Is_the_PII_that_the_system_collects_main PIIMain ON PIIMain.ParentContentId=ap.ContentId
         LEFT JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Does_the_system_support_the_activities_o PHIMain ON PHIMain.ParentContentId=ap.ContentId
         LEFT JOIN APP_CFACTS.SHARED.SEC_VW_enum_Is_the_PII_that_the_system_collects_main PIIMainEnum ON PIIMainEnum.Id=PIIMain.Value
         LEFT JOIN APP_CFACTS.SHARED.SEC_VW_enum_Does_the_system_support_the_activities_o PHIMainEnum ON PHIMainEnum.Id=PHIMain.Value
         left join APP_CFACTS.SHARED.SEC_VW_enum_Financial_System as efs on efs.Id = apfs.value),
   AVulnRiskToleranceCte as (SELECT VW.PRIMARY_FISMA_ID_DERIVED,V.INSTANCEID,
                  CAST(SUM(IFF((v.exploitAvailable='Yes'), (2*(datediff(days, v.firstseen, v.lastseen))*(IFF(v.BASESCORE='',1,to_double(v.BASESCORE)))*OATO_Category),
             ((datediff(days, v.firstseen, v.lastseen))*(IFF(v.BASESCORE='',1,to_double(v.BASESCORE)))*OATO_Category))) / (IFF(COUNT(1)=0,1,COUNT(1))) AS DECIMAL(8,2)) as AVRT
            FROM (select distinct INSTANCEID,CVE,BASESCORE,min(FIRSTSEEN) FIRSTSEEN,max(LASTSEEN) LASTSEEN,EXPLOITAVAILABLE 
                    from APP_TENABLE.SHARED.SEC_VW_VULN_WKFINDINGS -- 230824 changed DB name from TENABLE to APP_TENABLE 
                    where SEVERITY_NAME !='Info' and cve is not null 
                    group by INSTANCEID,cve,basescore,EXPLOITAVAILABLE) v
          JOIN APP_CDM.SHARED.SEC_VW_HWAM_AWS VW using(INSTANCEID)
          JOIN APP_CFACTS.SHARED.SEC_VW_AUTHORIZATION_PACKAGE AP on AP.IDUID=VW.PRIMARY_FISMA_ID_DERIVED
          JOIN OACategoryCte OA on OA.Acronym = AP.Acronym
          WHERE VW.InstanceStatus not like '%stop%'
          GROUP BY VW.PRIMARY_FISMA_ID_DERIVED,v.INSTANCEID),
    VulnRiskToleranceCte as (SELECT AV.PRIMARY_FISMA_ID_DERIVED
                  ,cast(AV.total_avrt/IFF(CA.awsAssetTotal=0,1,CA.awsAssetTotal) as decimal(10,2)) as VRT 
          FROM (select PRIMARY_FISMA_ID_DERIVED,SUM(IFNULL(AVRT,0)) total_avrt from AVulnRiskToleranceCte GROUP BY PRIMARY_FISMA_ID_DERIVED) AV
          JOIN CurAWSAssetTotalCte CA using(PRIMARY_FISMA_ID_DERIVED)
          ),
    CloudSrvProviderCte as (select ap.ContentId, concat('[',listagg(ecsp1.value,', ') within group (order by ap.ContentId), ']') as CldSrvcPrvd
              from APP_CFACTS.SHARED.SEC_VW_Authorization_Package as ap 
                    left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Cloud_Service_Provider_1 as apcsp1 on apcsp1.ParentContentId=ap.ContentId 
                    left join APP_CFACTS.SHARED.SEC_VW_enum_Cloud_Service_Provider_1 as ecsp1 on ecsp1.Id = apcsp1.value     
              group by ap.ContentId)          
SELECT 
       ap.Acronym Acronym    
    ,eoardy.value as "OA Ready"
    ,eoastat.value OA_Status
	,IFNULL(totalPoamsRBDTbl.residualRisk, 0) as "ResidualRisk"
    ,(IFNULL(cAWSAsstTbl.awsAssetTotal,0)) as "TotalAssets"
    ,CAST(((IFNULL(lstMnthAsstTbl.lstMnthTotCnt,0) - IFNULL(cAWSAsstTbl.awsAssetTotal,0))*100.00)/IFNULL(lstMnthAsstTbl.lstMnthTotCnt,1) AS DECIMAL(8,2)) as "Asset Risk Tolerance"
    ,OACategoryTbl.OATO_Category as OATO_Category
    ,ehvalst.value as HVAStatus
    ,IFF(contains(mefstatusTbl.mefstatus, 'N/A'),'NULL',(iff(len(mefstatusTbl.mefstatus)>0,'Yes','NULL'))) as MEFStatus
    ,ersc.value as FIPS_199_Overall_Impact_Rating   
    ,IFF((PIIMainEnum.value IS NOT NULL AND PIIMainEnum.value='Yes') OR 
         (PHIMainEnum.value IS NOT NULL AND PHIMainEnum.value='Yes'), 'Yes', 'NULL') as PII_PHI
    ,efs.value as Financial_System
    ,ap.component_acronym as Component
    ,'TBD' as "DevSecOPS / CSM"
    ,grpAcronymTbl.groupAcronym as Group_Acronym
    ,IFF(CONTAINS(cloudSrvcPrvdTbl.CldSrvcPrvd,'Amazon Web Services'),'Yes','No') as In_CMS_Cloud        
    ,ap.Last_ACT_Date as Last_ACT_Date
    ,ap.Last_ACT_SCA_Final_Report_Date as Last_ACT_SCA_Final_Report_Date
    ,ap.Last_Pentest_Date as Last_Pentest_Date
    ,'No' as Is_SecurityHub_Enabled
    ,ap.Authorization_Package_Name as System
    ,etlcph.value as TLC_Phase
    ,IFNULL(vulnRTTbl.VRT,0) as "Vuln Risk Tolerance"
    ,IFNULL(rtbl.ResiliencyScore,0) as "Resiliency Score"
    ,0 as "Is_MarketPlace" 

 from APP_CFACTS.SHARED.SEC_VW_Authorization_Package as ap
      left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_OA_Ready as apoardy on apoardy.ParentContentId=ap.ContentId 
      left join APP_CFACTS.SHARED.SEC_VW_enum_OA_Ready as eoardy on eoardy.Id = apoardy.value
      left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_OA_Ready_With_Hosting as apoardywh on apoardywh.ParentContentId=ap.ContentId 
      left join APP_CFACTS.SHARED.SEC_VW_enum_OA_Ready_With_Hosting as eoardywh on eoardywh.Id = apoardywh.value
      left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_OA_Status as apoastat on apoastat.ParentContentId=ap.ContentId 
      left join APP_CFACTS.SHARED.SEC_VW_enum_OA_Status as eoastat on eoastat.Id = apoastat.value
      left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Is_this_system_on_the_HVA_tracking_list as aphvalst on aphvalst.ParentContentId=ap.ContentId 
      left join APP_CFACTS.SHARED.SEC_VW_enum_GVL_YesNo as ehvalst on ehvalst.Id = aphvalst.value
      left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_TLC_Phase as aptlcph on aptlcph.ParentContentId=ap.ContentId 
      left join APP_CFACTS.SHARED.SEC_VW_enum_XLC_Phase as etlcph on etlcph.Id = aptlcph.value      
      left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Financial_System as apfs on apfs.ParentContentId=ap.ContentId 
      left join APP_CFACTS.SHARED.SEC_VW_enum_Financial_System as efs on efs.Id = apfs.value
      left join APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Recommended_Security_Category as aprsc on aprsc.ParentContentId=ap.ContentId 
      left join APP_CFACTS.SHARED.SEC_VW_enum_Security_Category as ersc on ersc.Id = aprsc.value      
      LEFT JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Is_the_PII_that_the_system_collects_main PIIMain ON PIIMain.ParentContentId=ap.ContentId
      LEFT JOIN APP_CFACTS.SHARED.SEC_VW_Authorization_Package_Does_the_system_support_the_activities_o PHIMain ON PHIMain.ParentContentId=ap.ContentId
      LEFT JOIN APP_CFACTS.SHARED.SEC_VW_enum_Is_the_PII_that_the_system_collects_main PIIMainEnum ON PIIMainEnum.Id=PIIMain.Value
      LEFT JOIN APP_CFACTS.SHARED.SEC_VW_enum_Does_the_system_support_the_activities_o PHIMainEnum ON PHIMainEnum.Id=PHIMain.Value
	  left join TotalPOAMSRBDCte as totalPoamsRBDTbl on totalPoamsRBDTbl.contentId=ap.contentId
      left join GroupAcronymCte as grpAcronymTbl on grpAcronymTbl.acronym=ap.acronym
      left join OACategoryCte as OACategoryTbl on OACategoryTbl.acronym=ap.acronym
      left join VulnRiskToleranceCte as vulnRTTbl on vulnRTTbl.PRIMARY_FISMA_ID_DERIVED=ap.iduid
      left join ResiliencyScoreCte as rtbl on rtbl.Tracking_id = ap.tracking_id
      left join CurAWSAssetTotalCte as cAWSAsstTbl on cAWSAsstTbl.PRIMARY_FISMA_ID_DERIVED= ap.iduid
      left join LastMonthAssetTotalCte as lstMnthAsstTbl on lstMnthAsstTbl.PRIMARY_FISMA_ID=ap.iduid
      left join MefStatusCte as mefStatusTbl on mefStatusTbl.contentId=ap.contentId
      left join PackageTypeCte as PackageTypeTbl on PackageTypeTbl.contentId=ap.contentId
      left join InfoSysTypeCte as InfoSysTypeTbl on InfoSysTypeTbl.contentId=ap.contentId
      left join CloudSrvProviderCte as cloudSrvcPrvdTbl on cloudSrvcPrvdTbl.contentId=ap.contentId
    where ((etlcph.value = 'Operate' and PackageTypeTbl.packagetype = 'Information System' 
                and (InfoSysTypeTbl.infosystype IN 
                      ('Major Application'
                      ,'General Support System'
                      ,'Minor Application [Stand Alone]'
                      ,'Minor Application [Child]'))))

);