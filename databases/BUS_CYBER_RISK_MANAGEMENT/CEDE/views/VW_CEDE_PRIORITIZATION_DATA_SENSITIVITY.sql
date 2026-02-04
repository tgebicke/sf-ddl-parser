create or replace view VW_CEDE_PRIORITIZATION_DATA_SENSITIVITY(
	AUTHORIZATION_PACKAGE,
	MAX,
	MIN,
	NORM_DATA_SENSITIVITY
) COMMENT='Contains prioritization and data sensitivity data at org hierarchy level'
 as
/* About the view: Data sensitivity scoring is based on the type of data that is collected, processed, and stored by the systems, as reported in their PIA documents. 
Part of the score is based on a system's overall PII level. Sensitive systems get a score of 6, Combine-Context 4, Non-sensitive 2 and No PII 0.
The above score is also combined with a FIPS-199 score for the system, with the following scores: High 1, Moderate 0.05.
The basic data sensitivity score will range from 0 -7.  The higher the number, the higher the data sensitivity is.
The field 'norm_data_sensitivty' normalizes the scores across all systems from 0-1.*/
SELECT c.AUTHORIZATION_PACKAGE,
 MAX(c.pii_score + c.fips_score) OVER() as MAX,
 MIN(c.pii_score + c.fips_score) OVER() as MIN,
 ROUND(((c.pii_score + c.fips_score)-(MIN(c.pii_score + c.fips_score) OVER()))/((MAX(c.pii_score + c.fips_score) OVER())-(MIN(c.pii_score + c.fips_score) OVER())),3) as norm_data_sensitivity
FROM 
(SELECT a.AUTHORIZATION_PACKAGE
      ,a.FIPS_199_OVERALL_IMPACT_RATING
      ,b.SYS_PII_LEVEL
      ,CASE when b.SYS_PII_LEVEL='Sensitive PII' then 6
           when b.SYS_PII_LEVEL='Context-Combine PII' then 4
           when b.SYS_PII_LEVEL='Non-sensitive PII' then 2 
           when b.SYS_PII_LEVEL='No PII' then 0
      END AS pii_score
     ,CASE WHEN a.FIPS_199_OVERALL_IMPACT_RATING = 'Moderate' then .05
          when a.FIPS_199_OVERALL_IMPACT_RATING = 'High' then 1
          when a.FIPS_199_OVERALL_IMPACT_RATING = 'Low' then 0
      END as fips_score
 FROM CEDE.VW_CEDE_AUTHORIZATION_PACKAGES a
 LEFT JOIN CEDE.VW_CEDE_SYSTEM_PII_LEVEL b ON a.AUTHORIZATION_PACKAGE = b.AUTHORIZATION_PACKAGE) c;