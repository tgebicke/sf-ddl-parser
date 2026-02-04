create or replace view VW_ALLOCATEDCONTROL(
	ID,
	CONTROL_NUMBER,
	CONTROL_ELEMENT_NUMBER,
	ACRONYM,
	ALLOCATION_STATUS,
	AUTHORIZATION_PACKAGE,
	CONTROL_FAMILY,
	CONTROL_NAME,
	CONTROL_NUMBER_COMBO,
	CONTROL_SET_VERSION_NUMBER,
	HYBRID_CONTROL,
	INHERITABLE_BY_OTHER_SYSTEMS,
	LAST_ACT_DATE,
	LAST_ASSESSMENT_DATE,
	LAST_PENTEST_DATE,
	LAST_SCA_DATE,
	OVERALL_CONTROL_STATUS,
	PRIVATE_IMP_UPDATED_DATE,
	SHARED_IMP_UPDATED_DATE,
	TRACKING_ID,
	ALLOCATED_CONTROL_SYSTEM_ID,
	SYSTEM_ID,
	CONTROL_ELEMENT,
	RESPONSIBILITY,
	SIGNIFICANT_CONTROL_CHANGE,
	SIGNIFICANT_CONTROL_CHANGE_DETAILS
) COMMENT='Return all Allocated controls from CFACTS.'
 as
SELECT ac.ID
--,ac.INSERT_DATE
,ac.Control_Number
,ac.Control_Element_Number
,s.Acronym
,ac.Allocation_Status
,s.Authorization_Package
,ac.Control_Family
,ac.Control_Name
,ac.Control_Number_Combo
,ac.Control_Set_Version_Number
,ac.hybrid_control
,ac.Inheritable_by_other_systems
,ac.Last_ACT_Date
,ac.Last_Assessment_Date
,ac.Last_Pentest_Date
,ac.Last_SCA_Date
,ac.Overall_Control_Status
,ac.Private_Imp_Updated_Date
,ac.Shared_Imp_Updated_Date
,ac.Tracking_ID
,ac.SYSTEM_ID as Allocated_control_system_id
,s.SYSTEM_ID
,ac.Control_Element
,ac.Responsibility
,ac.Significant_Control_Change
,ac.Significant_Control_Change_Details
FROM CORE.AllocatedControl ac
JOIN CORE.VW_Systems s on s.SYSTEM_ID = ac.SYSTEM_ID;