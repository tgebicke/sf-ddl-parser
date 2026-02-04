create or replace view V_CRMP_PCTSYSTEMSAUTHORIZED(
	ACRONYM,
	AUTH_DECISION
) COMMENT='ATO system acronyms'
 as
SELECT s.Acronym
,s.Auth_Decision
FROM CORE.VW_Systems  s
where s.Is_OperationalSystem = 1 and s.Auth_Decision = 'ATO';