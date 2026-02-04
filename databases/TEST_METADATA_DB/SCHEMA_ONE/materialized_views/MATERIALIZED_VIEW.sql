create or replace materialized view MATERIALIZED_VIEW(
	USER_COUNT
) as
SELECT COUNT(*) AS user_count FROM test_metadata_db.schema_one.permanent_table;