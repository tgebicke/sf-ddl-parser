create or replace secure view SECURE_VIEW(
	ID,
	NAME
) as
SELECT id, name FROM test_metadata_db.schema_one.permanent_table;