create or replace view VW_FISMA_OPERATED_BY(
	FIPS_199_OVERALL_IMPACT_RATING,
	OPERATED_BY,
	TOTALSYSTEMS
) COMMENT='Fisma Report Total Systems by FIPS and Operated By'
 as
select fips_199_overall_impact_rating,operated_by,count(1) TotalSystems 
from core.VW_SYSTEMS
where is_operationalsystem = 1 and totalassets > 0 
group by fips_199_overall_impact_rating,operated_by
order by fips_199_overall_impact_rating,operated_by
;