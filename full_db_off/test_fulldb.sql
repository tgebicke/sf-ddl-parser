create or replace database TEST_METADATA_DB;

create or replace schema PUBLIC;

create or replace schema SCHEMA_ONE;

create or replace sequence ID_SEQ start with 1000 increment by 5 noorder;
create or replace TABLE PERMANENT_TABLE (
	ID NUMBER(38,0),
	NAME VARCHAR(16777216)
);
create or replace materialized view MATERIALIZED_VIEW(
	USER_COUNT
) as
SELECT COUNT(*) AS user_count FROM test_metadata_db.schema_one.permanent_table;

create or replace TRANSIENT TABLE TRANSIENT_TABLE (
	ID NUMBER(38,0),
	CREATED_AT TIMESTAMP_NTZ(9)
);
create or replace view REGULAR_VIEW(
	ID,
	NAME
) as
SELECT * FROM test_metadata_db.schema_one.permanent_table;
create or replace secure view SECURE_VIEW(
	ID,
	NAME
) as
SELECT id, name FROM test_metadata_db.schema_one.permanent_table;
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
	SKIP_HEADER = 1
;
CREATE OR REPLACE FUNCTION "CONCAT_STRINGS"("A" VARCHAR, "B" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS '
    a || ''_'' || b
';
create or replace stage INTERNAL_STAGE;
create or replace stream STREAM_ON_TABLE on table PERMANENT_TABLE;
create or replace pipe SAMPLE_PIPE auto_ingest=false as COPY INTO test_metadata_db.schema_one.permanent_table
FROM @test_metadata_db.schema_one.internal_stage
FILE_FORMAT = (FORMAT_NAME = test_metadata_db.schema_one.csv_format);
create or replace task INSERT_TASK
	schedule='USING CRON 0 0 * * * UTC'
	as INSERT INTO test_metadata_db.schema_one.permanent_table (id, name)
  SELECT id_seq.nextval, 'name_' || id_seq.nextval;
create or replace schema SCHEMA_TWO;

create or replace TABLE ORDERS (
	ORDER_ID NUMBER(38,0),
	USER_ID NUMBER(38,0),
	AMOUNT NUMBER(10,2),
	ORDER_DATE DATE
);
CREATE OR REPLACE FILE FORMAT JSON_FORMAT
	TYPE = JSON
	NULL_IF = ()
;
CREATE OR REPLACE PROCEDURE "RESET_ORDERS"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN
    DELETE FROM test_metadata_db.schema_two.orders;
    RETURN ''RESET COMPLETE'';
END;
';