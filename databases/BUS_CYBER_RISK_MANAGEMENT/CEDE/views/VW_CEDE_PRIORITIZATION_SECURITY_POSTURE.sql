create or replace view VW_CEDE_PRIORITIZATION_SECURITY_POSTURE(
	AUTHORIZATION_PACKAGE,
	SECURITY_POSTURE_TOTAL,
	MAX,
	MIN,
	NORM_SECURITY_POSTURE
) COMMENT='Contains Security Posture and prioritization data at org hierarchy level'
 as
/* About the view: A control category is assigned to each of the twenty-four encryption controls along with a scoring valueusing the following logic: 
Encryption Controls +11, Encryption Support +8, Tier 1 +1.1, Tier 2 +0.8, Tier 3 +0.5.
The score is applied if the control is satisfied. The expected results for a system will range 0-61.5).  
The security controls scoring scale is opposite of the other criteria:  a lower score is a ‘worse’ score and a higher priority
If a system in fact doesn’t satisfy any controls, then it’s score is 0 which makes it a high priority system to address.
The field 'norm_security posture' simply normalizes the scores across all systems  from 0-1. */
SELECT 
a.AUTHORIZATION_PACKAGE,
sum(a.security_posture) as security_posture_total,
MAX(sum(a.security_posture)) OVER() as max,
MIN(sum(a.security_posture)) OVER() as min,
ROUND((sum(a.security_posture)-(MIN(sum(a.security_posture)) OVER()))/((MAX(sum(a.security_posture)) OVER())-(MIN(sum(a.security_posture)) OVER())),3) as norm_security_posture
FROM (SELECT AUTHORIZATION_PACKAGE,
        OVERALL_CONTROL_STATUS,
        TIER,
        CASE
            WHEN TIER = 'Encryption' THEN (count(distinct(CONTROL_NUMBER)) * 11)
            WHEN TIER = 'Encryption Support' THEN (count(distinct(CONTROL_NUMBER)) * 8)
            WHEN TIER = 'Tier 1' THEN count(distinct(CONTROL_NUMBER)) * 1.1
            WHEN TIER = 'Tier 2' THEN count(distinct(CONTROL_NUMBER)) * 0.8
            WHEN TIER = 'Tier 3' THEN count(distinct(CONTROL_NUMBER)) * 0.5
            ELSE 0
        END AS security_posture
FROM CEDE.VW_CEDE_CONTROL_DETAIL_WITH_POAM
where OVERALL_CONTROL_STATUS='Satisfied'
GROUP BY AUTHORIZATION_PACKAGE,OVERALL_CONTROL_STATUS, TIER) a
GROUP BY a.AUTHORIZATION_PACKAGE
;