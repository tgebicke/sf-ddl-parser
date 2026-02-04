create or replace pipe SAMPLE_PIPE auto_ingest=false as COPY INTO test_metadata_db.schema_one.permanent_table
FROM @test_metadata_db.schema_one.internal_stage
FILE_FORMAT = (FORMAT_NAME = test_metadata_db.schema_one.csv_format);