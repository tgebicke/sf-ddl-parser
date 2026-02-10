"""Shared pytest fixtures for sfddl tests."""

import json
import pytest


MINIMAL_DDL = """
create or replace schema FOO;

create or replace table T1 (id number);

create or replace procedure "MY_PROC"() returns varchar language sql as 'begin return ''ok''; end';

create or replace procedure "MY_PROC"(x varchar, y number) returns varchar language sql as 'begin return x; end';

create or replace function "MY_FUNC"(a number) returns number language sql as 'a + 1';
"""


@pytest.fixture
def minimal_ddl():
    """Minimal DDL string: one schema FOO, one table T1, two procedures (0 and 2 args), one function."""
    return MINIMAL_DDL.strip()


@pytest.fixture
def valid_config_dict(tmp_path):
    """Valid config as a dict with paths under tmp_path."""
    sql_file = tmp_path / "full_db" / "fulldb.sql"
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    return {
        "account": "test.account",
        "user": "testuser",
        "warehouse": "WH",
        "database": "TEST_DB",
        "role": "ROLE",
        "auth_method": "password",
        "password": "secret",
        "sql_file": str(sql_file),
        "output_dir": str(tmp_path / "databases"),
        "backup_dir": str(tmp_path / "backups"),
    }


@pytest.fixture
def valid_config_path(valid_config_dict, tmp_path):
    """Write valid config to a JSON file and return its path."""
    config_path = tmp_path / "sfddl.json"
    with open(config_path, "w") as f:
        json.dump(valid_config_dict, f, indent=2)
    return config_path
