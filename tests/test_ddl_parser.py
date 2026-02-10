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
    restore_comments,
    prune_removed_files,
    parse_sql_by_database_and_schema,
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
    assert get_file_basename_for_object(ddl, "procedures") == "MY_PROC(x varchar, y number)"


def test_get_file_basename_for_object_function():
    ddl = "CREATE FUNCTION MY_FUNC(a number) RETURNS number LANGUAGE SQL AS 'a+1';"
    assert get_file_basename_for_object(ddl, "functions") == "MY_FUNC(a number)"


def test_get_file_basename_for_object_table():
    ddl = "CREATE TABLE T1 (id number)"
    assert get_file_basename_for_object(ddl, "tables") == "T1"


def test_get_file_basename_for_object_view():
    ddl = "CREATE VIEW V1 AS SELECT 1"
    assert get_file_basename_for_object(ddl, "views") == "V1"


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
    assert any("MY_PROC(" in n and "varchar" in n.lower() for n in names)

    func_dir = foo_dir / "functions"
    func_files = list(func_dir.glob("*.sql"))
    assert len(func_files) == 1
    assert "MY_FUNC" in func_files[0].stem
    assert "a number" in func_files[0].stem or "number" in func_files[0].read_text()


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
