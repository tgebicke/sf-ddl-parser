create or replace view VW_CRMP_TOTALNUMBERRISKACCEPTANCE(
	ACRONYM,
	TOTALPOAMWITHAPPROVEDRBD
) COMMENT='Show Risk acceptance for every systems, used for CRMP.'
 as
SELECT Acronym, TotalPOAMwithApprovedRBD FROM CORE.VW_Systems;