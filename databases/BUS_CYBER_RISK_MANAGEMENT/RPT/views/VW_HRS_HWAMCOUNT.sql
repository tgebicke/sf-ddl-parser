create or replace view VW_HRS_HWAMCOUNT(
	COMPONENTACRONYM,
	HWAM_PCT
) COMMENT='Contains summarized Asset details at component level'
 as
select ComponentAcronym,
cast ( Y / (Y + N ) as DECIMAL(18, 4))*100   hwam_pct
from
(
select "Component_Acronym" ComponentAcronym, cast(sum(case when (HWAM_CNT)<>0 then 1 else 0 end)as DECIMAL(18, 4)) as Y,
cast(sum(case when (HWAM_CNT)=0 then 1 else 0 end)as DECIMAL(18, 4))  as N
 from(
select  "Component_Acronym","System", sum("Total Assets") HWAM_CNT
from  rpt.V_CyberRisk_System_Summary
group by "Component_Acronym","System" ) A
group by "Component_Acronym"
)B;