create or replace view REGULAR_VIEW(
	ID,
	NAME
) as
SELECT * FROM test_metadata_db.schema_one.permanent_table;