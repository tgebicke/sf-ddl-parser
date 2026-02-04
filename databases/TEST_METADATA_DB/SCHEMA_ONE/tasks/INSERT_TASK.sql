create or replace task INSERT_TASK
	schedule='USING CRON 0 0 * * * UTC'
	as INSERT INTO test_metadata_db.schema_one.permanent_table (id, name)
  SELECT id_seq.nextval, 'name_' || id_seq.nextval;