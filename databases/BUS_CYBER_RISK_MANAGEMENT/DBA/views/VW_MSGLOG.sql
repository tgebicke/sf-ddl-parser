create or replace view VW_MSGLOG(
	ID,
	INSERT_DATE,
	APPL,
	MSG
) COMMENT='Visibility of process steps and warnings (Historical)\t'
 as
SELECT ID
,substring(INSERT_DATE::varchar,1,16) as INSERT_DATE
,APPL,MSG
FROM CORE.MSGLOG ORDER BY ID DESC;