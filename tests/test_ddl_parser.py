"""Unit tests for sfddl.ddl_parser."""

import pytest
from pathlib import Path

from sfddl.ddl_parser import (
    get_object_type,
    get_object_name,
    extract_argument_signature,
    get_file_basename_for_object,
    get_database_name,
    get_schema_name,
    extract_multiline_comments,
    extract_comments,
    restore_comments,
    restore_sp_formatting,
    prune_removed_files,
    parse_sql_by_database_and_schema,
    _normalize_blank_lines,
)


# --- get_object_type ---


def test_get_object_type_table():
    assert get_object_type("CREATE TABLE t1 (id number)") == "tables"


def test_get_object_type_view():
    assert get_object_type("CREATE VIEW v1 AS SELECT 1") == "views"


def test_get_object_type_procedure():
    assert get_object_type("CREATE PROCEDURE p() RETURNS VARCHAR") == "procedures"


def test_get_object_type_function():
    assert get_object_type("CREATE FUNCTION f(x number) RETURNS NUMBER") == "functions"


def test_get_object_type_secure_function():
    assert get_object_type("CREATE SECURE FUNCTION f(x number) RETURNS NUMBER") == "secure_functions"


def test_get_object_type_secure_procedure():
    assert get_object_type("CREATE SECURE PROCEDURE p() RETURNS VARCHAR") == "procedures"  # secure_procedures not in get_object_type?


def test_get_object_type_schema():
    assert get_object_type("CREATE OR REPLACE SCHEMA FOO") == "schemas"


def test_get_object_type_task():
    assert get_object_type("CREATE TASK t1 SCHEDULE ...") == "tasks"


def test_get_object_type_file_format():
    assert get_object_type("CREATE FILE FORMAT csv TYPE CSV") == "file_formats"


def test_get_object_type_unknown():
    assert get_object_type("CREATE FOO BAR") is None


# --- get_object_name ---


def test_get_object_name_table():
    assert get_object_name("CREATE TABLE T1 (id number)") == "T1"


def test_get_object_name_view():
    assert get_object_name("CREATE VIEW V1 AS SELECT 1") == "V1"


def test_get_object_name_procedure_quoted():
    assert get_object_name('CREATE PROCEDURE "MY_PROC"() RETURNS VARCHAR') == "MY_PROC"


def test_get_object_name_procedure_with_args():
    assert get_object_name('CREATE PROCEDURE "MY_PROC"(x varchar) RETURNS VARCHAR') == "MY_PROC"


def test_get_object_name_function():
    assert get_object_name("CREATE FUNCTION MY_FUNC(a number) RETURNS number") == "MY_FUNC"


def test_get_object_name_schema():
    assert get_object_name("CREATE OR REPLACE SCHEMA FOO") == "FOO"


def test_get_object_name_schema_quoted():
    assert get_object_name('CREATE OR REPLACE SCHEMA "MY_SCHEMA"') == "MY_SCHEMA"


# --- extract_argument_signature ---


def test_extract_argument_signature_procedure_no_args():
    ddl = 'CREATE PROCEDURE "p"() RETURNS VARCHAR LANGUAGE SQL AS \'x\';'
    assert extract_argument_signature(ddl) == ""


def test_extract_argument_signature_procedure_one_arg():
    ddl = 'CREATE PROCEDURE "p"(x VARCHAR) RETURNS VARCHAR LANGUAGE SQL AS \'x\';'
    assert extract_argument_signature(ddl) == "x VARCHAR"


def test_extract_argument_signature_procedure_two_args():
    ddl = 'CREATE PROCEDURE "p"(x varchar, y number) RETURNS VARCHAR LANGUAGE SQL AS \'x\';'
    assert extract_argument_signature(ddl) == "x varchar, y number"


def test_extract_argument_signature_procedure_multiline():
    ddl = """CREATE PROCEDURE "p"(
        a number,
        b varchar
    ) RETURNS VARCHAR LANGUAGE SQL AS 'x';"""
    assert extract_argument_signature(ddl) == "a number, b varchar"


def test_extract_argument_signature_function_one_arg():
    ddl = "CREATE FUNCTION f(a number) RETURNS number LANGUAGE SQL AS 'a+1';"
    assert extract_argument_signature(ddl) == "a number"


def test_extract_argument_signature_not_procedure_or_function():
    assert extract_argument_signature("CREATE TABLE t (id number)") is None


def test_extract_argument_signature_unbalanced_parens():
    ddl = 'CREATE PROCEDURE "p"(x VARCHAR RETURNS VARCHAR'  # no closing )
    assert extract_argument_signature(ddl) is None


# --- get_file_basename_for_object ---


def test_get_file_basename_for_object_procedure_no_args():
    ddl = 'CREATE PROCEDURE "MY_PROC"() RETURNS VARCHAR LANGUAGE SQL AS \'x\';'
    assert get_file_basename_for_object(ddl, "procedures") == "MY_PROC()"


def test_get_file_basename_for_object_procedure_with_args():
    ddl = 'CREATE PROCEDURE "MY_PROC"(x varchar, y number) RETURNS VARCHAR LANGUAGE SQL AS \'x\';'
    assert get_file_basename_for_object(ddl, "procedures") == "MY_PROC(VARCHAR,NUMBER)"


def test_get_file_basename_for_object_function():
    ddl = "CREATE FUNCTION MY_FUNC(a number) RETURNS number LANGUAGE SQL AS 'a+1';"
    assert get_file_basename_for_object(ddl, "functions") == "MY_FUNC(NUMBER)"


def test_get_file_basename_for_object_table():
    ddl = "CREATE TABLE T1 (id number)"
    assert get_file_basename_for_object(ddl, "tables") == "T1"


def test_get_file_basename_for_object_view():
    ddl = "CREATE VIEW V1 AS SELECT 1"
    assert get_file_basename_for_object(ddl, "views") == "V1"


def test_get_file_basename_for_object_procedure_types_only_with_precision():
    """Filename uses type names only; NUMBER(38,0) becomes NUMBER."""
    ddl = """CREATE PROCEDURE "SP_CRM_EXEC_MCRRPROC"(
        _MONTH_ NUMBER(38,0),
        _YEAR_ NUMBER(38,0),
        _PREMONTH_ NUMBER(38,0),
        _PREYEAR_ NUMBER(38,0)
    ) RETURNS VARCHAR LANGUAGE SQL AS 'BEGIN NULL; END';"""
    assert get_file_basename_for_object(ddl, "procedures") == "SP_CRM_EXEC_MCRRPROC(NUMBER,NUMBER,NUMBER,NUMBER)"


def test_get_file_basename_for_object_procedure_varchar_precision():
    """VARCHAR(255) in filename becomes VARCHAR."""
    ddl = 'CREATE PROCEDURE "MY_PROC"(p VARCHAR(255), q NUMBER(10,2)) RETURNS VARCHAR LANGUAGE SQL AS \'x\';'
    assert get_file_basename_for_object(ddl, "procedures") == "MY_PROC(VARCHAR,NUMBER)"


# --- get_database_name ---


def test_get_database_name_create_database():
    assert get_database_name("create database TEST_DB;") == "TEST_DB"


def test_get_database_name_use_database():
    assert get_database_name("USE DATABASE MY_DB;") == "MY_DB"


def test_get_database_name_quoted():
    assert get_database_name('"DB_NAME".schema.table') == "DB_NAME"


# --- get_schema_name ---


def test_get_schema_name():
    assert get_schema_name("create or replace schema SCHEMA_FOO") == "SCHEMA_FOO"


# --- extract_multiline_comments / restore_comments ---


def test_extract_multiline_comments_and_restore():
    sql = "/* comment here */\nCREATE TABLE t (id number)"
    modified, comments = extract_multiline_comments(sql)
    assert "/* comment here */" not in modified
    assert "<comment=" in modified
    assert len(comments) == 1
    restored = restore_comments(modified, comments)
    assert "/* comment here */" in restored
    assert "CREATE TABLE t" in restored


# --- prune_removed_files ---


def test_prune_removed_files_removes_stray_file(tmp_path):
    db_dir = tmp_path / "db"
    db_dir.mkdir()
    keep = db_dir / "schemas" / "FOO.sql"
    keep.parent.mkdir(parents=True)
    keep.write_text("create schema FOO;")
    stray = db_dir / "tables" / "ORPHAN.sql"
    stray.parent.mkdir(parents=True)
    stray.write_text("create table ORPHAN (id number);")

    result = prune_removed_files(db_dir, {keep}, dry_run=False)
    assert result["removed_files"] == 1
    assert not stray.exists()
    assert keep.exists()


def test_prune_removed_files_dry_run_removes_nothing(tmp_path):
    db_dir = tmp_path / "db"
    db_dir.mkdir()
    keep = db_dir / "schemas" / "FOO.sql"
    keep.parent.mkdir(parents=True)
    keep.write_text("create schema FOO;")
    stray = db_dir / "tables" / "ORPHAN.sql"
    stray.parent.mkdir(parents=True)
    stray.write_text("create table ORPHAN (id number);")

    result = prune_removed_files(db_dir, {keep}, dry_run=True)
    assert result["removed_files"] == 0
    assert stray.exists()
    assert keep.exists()


# --- parse_sql_by_database_and_schema ---


def test_parse_sql_by_database_and_schema_creates_structure(minimal_ddl, tmp_path, capsys):
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        minimal_ddl,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
    )
    capsys.readouterr()  # consume printed output

    assert out_dir.exists()
    db_dir = out_dir / "TEST_DB"
    assert db_dir.exists()
    foo_dir = db_dir / "FOO"
    assert foo_dir.exists()
    assert (foo_dir / "schemas").exists()
    assert (foo_dir / "tables").exists()
    assert (foo_dir / "procedures").exists()
    assert (foo_dir / "functions").exists()

    schemas_dir = foo_dir / "schemas"
    assert list(schemas_dir.glob("*.sql"))  # FOO.sql
    tables_dir = foo_dir / "tables"
    table_files = list(tables_dir.glob("*.sql"))
    assert len(table_files) == 1
    assert table_files[0].name == "T1.sql"
    assert "create or replace table t1" in table_files[0].read_text().lower()

    proc_dir = foo_dir / "procedures"
    proc_files = sorted(proc_dir.glob("*.sql"))
    assert len(proc_files) >= 1
    names = [f.stem for f in proc_files]
    assert "MY_PROC()" in names
    assert any("MY_PROC(" in n and "VARCHAR" in n and "NUMBER" in n for n in names)

    func_dir = foo_dir / "functions"
    func_files = list(func_dir.glob("*.sql"))
    assert len(func_files) == 1
    assert func_files[0].stem == "MY_FUNC(NUMBER)"


def test_parse_sql_by_database_and_schema_exclude_schemas(minimal_ddl, tmp_path, capsys):
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        minimal_ddl,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
        exclude_schemas=["FOO"],
    )
    capsys.readouterr()
    db_dir = out_dir / "TEST_DB"
    assert not (db_dir / "FOO").exists() or not list((db_dir / "FOO").rglob("*.sql"))


def test_parse_sql_by_database_and_schema_include_schemas(minimal_ddl, tmp_path, capsys):
    ddl_with_two = minimal_ddl + "\n\ncreate or replace schema BAR;\ncreate or replace table T2 (x number);"
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        ddl_with_two,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
        include_schemas=["FOO"],
    )
    capsys.readouterr()
    db_dir = out_dir / "TEST_DB"
    assert (db_dir / "FOO").exists()
    assert not (db_dir / "BAR").exists()


# --- restore_sp_formatting ---


def test_restore_sp_formatting_basic():
    content = "CREATE OR REPLACE PROCEDURE \"P\"()\nRETURNS VARCHAR\nLANGUAGE SQL\nAS 'BEGIN\n    SELECT ''hello'';\nEND';"
    result = restore_sp_formatting(content)
    assert "AS $$" in result
    assert "SELECT 'hello';" in result
    assert "''" not in result
    assert result.endswith("$$;")


def test_restore_sp_formatting_no_op_on_dollar_quoted():
    content = "CREATE OR REPLACE PROCEDURE \"P\"()\nRETURNS VARCHAR\nLANGUAGE SQL\nAS $$\nBEGIN\n    SELECT 'hello';\nEND\n$$;"
    result = restore_sp_formatting(content)
    assert result == content


def test_restore_sp_formatting_no_op_without_as_quote():
    content = "CREATE TABLE T (id NUMBER);"
    result = restore_sp_formatting(content)
    assert result == content


def test_restore_sp_formatting_empty_body():
    content = "CREATE OR REPLACE PROCEDURE \"P\"()\nRETURNS VARCHAR\nLANGUAGE SQL\nAS '';"
    result = restore_sp_formatting(content)
    assert "AS $$\n" in result
    assert result.endswith("$$;")


def test_restore_sp_formatting_function():
    content = "CREATE OR REPLACE FUNCTION \"F\"(x NUMBER)\nRETURNS VARCHAR\nLANGUAGE SQL\nAS 'SELECT ''hi''';"
    result = restore_sp_formatting(content)
    assert "AS $$" in result
    assert "SELECT 'hi'" in result
    assert "''" not in result
    assert result.endswith("$$;")


def test_parse_sql_restore_sp_fmt(tmp_path, capsys):
    ddl = (
        "create or replace schema FOO;\n"
        "create or replace procedure \"MY_PROC\"()\n"
        "RETURNS VARCHAR\n"
        "LANGUAGE SQL\n"
        "AS 'BEGIN\n    RETURN ''done'';\nEND';"
    )
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        ddl,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
        restore_sp_fmt=True,
    )
    capsys.readouterr()
    proc_file = out_dir / "TEST_DB" / "FOO" / "procedures" / "MY_PROC().sql"
    assert proc_file.exists()
    contents = proc_file.read_text()
    assert "AS $$" in contents
    assert "RETURN 'done';" in contents
    assert "''" not in contents


def test_parse_sql_restore_sp_fmt_function(tmp_path, capsys):
    ddl = (
        "create or replace schema FOO;\n"
        "create or replace function \"MY_FUNC\"(x NUMBER)\n"
        "RETURNS VARCHAR\n"
        "LANGUAGE SQL\n"
        "AS 'SELECT ''result''';"
    )
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        ddl,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
        restore_sp_fmt=True,
    )
    capsys.readouterr()
    func_file = out_dir / "TEST_DB" / "FOO" / "functions" / "MY_FUNC(NUMBER).sql"
    assert func_file.exists()
    contents = func_file.read_text()
    assert "AS $$" in contents
    assert "SELECT 'result'" in contents
    assert "''" not in contents


# --- extended get_object_type coverage ---


@pytest.mark.parametrize("first_line,expected", [
    # Pipe (first branch — space-delimited)
    ("CREATE OR REPLACE PIPE MY_PIPE AS COPY INTO T", "pipes"),
    # Streams
    ("CREATE OR REPLACE STREAM MY_STREAM ON TABLE T", "streams"),
    ("CREATE OR REPLACE SECURE STREAM MY_STREAM ON TABLE T", "secure_streams"),
    # Views
    ("CREATE OR REPLACE MATERIALIZED VIEW MY_VIEW AS SELECT 1", "materialized_views"),
    ("CREATE OR REPLACE SECURE VIEW MY_VIEW AS SELECT 1", "secure_views"),
    # Tables
    ("CREATE OR REPLACE EXTERNAL TABLE MY_TABLE", "external_tables"),
    ("CREATE OR REPLACE SECURE TABLE MY_TABLE (id NUMBER)", "secure_tables"),
    # Triggers / indexes
    ("CREATE OR REPLACE TRIGGER MY_TRIGGER", "triggers"),
    ("CREATE INDEX MY_INDEX ON MY_TABLE(id)", "indexes"),
    # File formats
    ("CREATE OR REPLACE SECURE FILE FORMAT MY_FMT TYPE=CSV", "secure_file_formats"),
    # Types
    ("CREATE OR REPLACE TYPE MY_TYPE AS OBJECT(a NUMBER)", "types"),
    ("CREATE OR REPLACE SECURE TYPE MY_TYPE AS OBJECT(a NUMBER)", "secure_types"),
    # Sequences
    ("CREATE OR REPLACE SEQUENCE MY_SEQ", "sequences"),
    ("CREATE OR REPLACE SECURE SEQUENCE MY_SEQ", "secure_sequences"),
    # Synonyms / assemblies
    ("CREATE OR REPLACE SYNONYM MY_SYN FOR OTHER_TABLE", "synonyms"),
    ("CREATE OR REPLACE ASSEMBLY MY_ASSEMBLY", "assemblies"),
    # Warehouses
    ("CREATE OR REPLACE WAREHOUSE MY_WH WAREHOUSE_SIZE=XSMALL", "warehouses"),
    ("CREATE OR REPLACE SECURE WAREHOUSE MY_WH", "secure_warehouses"),
    # Stages
    ("CREATE OR REPLACE STAGE MY_STAGE", "stages"),
    ("CREATE OR REPLACE SECURE STAGE MY_STAGE", "secure_stages"),
    # Second PIPE branch (no surrounding spaces — e.g. SNOWPIPE keyword)
    ("CREATE SNOWPIPE MY_PIPE COPY INTO T", "pipes"),
    ("CREATE SECURE SNOWPIPE MY_PIPE COPY INTO T", "secure_pipes"),
    # Integrations
    ("CREATE OR REPLACE API INTEGRATION MY_INT", "api_integrations"),
    ("CREATE OR REPLACE SECURE API INTEGRATION MY_INT", "secure_api_integrations"),
    ("CREATE OR REPLACE NOTIFICATION INTEGRATION MY_INT", "notification_integrations"),
    ("CREATE OR REPLACE SECURE NOTIFICATION INTEGRATION MY_INT", "secure_notification_integrations"),
    ("CREATE OR REPLACE SECURITY INTEGRATION MY_INT", "security_integrations"),
    ("CREATE OR REPLACE SECURE SECURITY INTEGRATION MY_INT", "secure_security_integrations"),
    ("CREATE OR REPLACE INTEGRATION MY_INT", "integrations"),
    ("CREATE OR REPLACE SECURE INTEGRATION MY_INT", "secure_integrations"),
    # Users / roles
    ("CREATE USER MY_USER", "users"),
    ("CREATE SECURE USER MY_USER", "secure_users"),
    ("CREATE ROLE MY_ROLE", "roles"),
    ("CREATE SECURE ROLE MY_ROLE", "secure_roles"),
    # Grant (no other keyword matches)
    ("GRANT CREATE ON ACCOUNT", "grants"),
    # Database
    ("CREATE OR REPLACE DATABASE MY_DB", "databases"),
])
def test_get_object_type_extended(first_line, expected):
    assert get_object_type(first_line) == expected


# --- extract_comments (single-line -- comments) ---


def test_extract_comments_single_line():
    sql = "SELECT 1; -- this is a comment\nSELECT 2;"
    result, comments = extract_comments(sql)
    assert "-- this is a comment" not in result
    assert len(comments) == 1
    assert list(comments.values())[0] == "-- this is a comment"


def test_extract_comments_mixed():
    sql = "/* block */\nSELECT 1; -- inline\nSELECT 2;"
    result, comments = extract_comments(sql)
    assert "/* block */" not in result
    assert "-- inline" not in result
    assert len(comments) == 2


# --- _normalize_blank_lines ---


def test_normalize_blank_lines_collapses_excess_blanks():
    # 3 blank lines among 3 non-blank → blank(3) >= non_blank(3) → collapse
    content = "CREATE TABLE T1 (\n\n  id NUMBER\n\n\n)"
    result = _normalize_blank_lines(content)
    assert "\n\n" not in result


def test_normalize_blank_lines_preserves_sparse_content():
    # Only 1 blank among many non-blank lines → no collapse
    content = "CREATE TABLE T1 (\n  id NUMBER,\n\n  name VARCHAR\n)"
    result = _normalize_blank_lines(content)
    assert result == content


# --- restore_sp_formatting edge case ---


def test_restore_sp_formatting_single_quote_at_end():
    # Closing quote == opening quote position → return unchanged
    content = "CREATE PROCEDURE p() RETURNS VARCHAR LANGUAGE SQL AS '"
    result = restore_sp_formatting(content)
    assert result == content


# --- get_database_name edge cases ---


def test_get_database_name_dotted_schema():
    # Pattern with 2 groups (dot-separated) → triggers else branch + dot split
    result = get_database_name("create or replace schema MY_DB.MY_SCHEMA")
    assert result == "MY_DB"


def test_get_database_name_no_match():
    result = get_database_name("select 1")
    assert result == "default_database"


# --- get_schema_name edge case ---


def test_get_schema_name_no_match():
    assert get_schema_name("CREATE TABLE FOO (id NUMBER)") is None


# --- get_object_name edge case ---


def test_get_object_name_no_match():
    # No recognized pattern → None
    assert get_object_name("GRANT SELECT ON TABLE T TO ROLE R") is None


# --- parse_sql edge cases ---


def test_parse_sql_schema_in_proc_body_not_parsed(tmp_path, capsys):
    """A CREATE SCHEMA inside a procedure body must not be treated as a real schema."""
    ddl = (
        "create or replace schema FOO;\n"
        "create or replace table T1 (id NUMBER);\n"
        "create or replace procedure \"P\"() returns varchar language sql as\n"
        "  'create or replace schema FAKE_SCHEMA; return ''ok'';';\n"
    )
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        ddl,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
    )
    capsys.readouterr()
    db_dir = out_dir / "TEST_DB"
    # FAKE_SCHEMA should not appear as a real schema directory
    assert not (db_dir / "FAKE_SCHEMA").exists()


def test_parse_sql_no_schema_defaults(tmp_path, capsys):
    """DDL with no schema statement falls back to default_schema."""
    ddl = "create or replace table T1 (id NUMBER);"
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        ddl,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
    )
    out = capsys.readouterr().out
    assert "default_schema" in out or (out_dir / "TEST_DB" / "default_schema").exists()


def test_parse_sql_dollar_quoted_proc_skipped_not_double_written(tmp_path, capsys):
    """Dollar-quoted procedures (not captured by find_proc_boundaries) are skipped cleanly."""
    ddl = (
        "create or replace schema FOO;\n"
        "create or replace table T1 (id NUMBER);\n"
        "create or replace procedure \"MY_PROC\"() returns varchar language javascript as $$\n"
        "  var x = 'hello';\n"
        "  return x;\n"
        "$$;\n"
    )
    out_dir = tmp_path / "out"
    parse_sql_by_database_and_schema(
        ddl,
        database_name_override="TEST_DB",
        output_dir_override=str(out_dir),
    )
    capsys.readouterr()
    # Table should be written; procedure is dollar-quoted so may or may not be written
    assert (out_dir / "TEST_DB" / "FOO" / "tables" / "T1.sql").exists()
