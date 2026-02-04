create or replace view V_CFACTS_USERLIST(
	USER_ID
) COMMENT='Simple list of distinct CFACTS user IDs'
 as
SELECT DISTINCT USER_ID FROM CORE.CFACTS_USERMAPPING order by USER_ID
;