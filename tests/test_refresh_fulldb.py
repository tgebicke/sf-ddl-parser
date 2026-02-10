"""Tests for sfddl.refresh_fulldb (load_config, save_ddl_to_file). No Snowflake connection."""

import json
import pytest

from sfddl.refresh_fulldb import load_config, save_ddl_to_file


def test_load_config_valid(valid_config_path):
    config = load_config(str(valid_config_path))
    assert config["account"] == "test.account"
    assert config["database"] == "TEST_DB"
    assert "sql_file" in config


def test_load_config_missing_file(tmp_path):
    with pytest.raises(SystemExit):
        load_config(str(tmp_path / "nonexistent.json"))


def test_load_config_invalid_json(tmp_path):
    bad_path = tmp_path / "bad.json"
    bad_path.write_text("{ invalid json")
    with pytest.raises(SystemExit):
        load_config(str(bad_path))


def test_load_config_missing_required_field(tmp_path):
    config_path = tmp_path / "sfddl.json"
    config_path.write_text(
        json.dumps({
            "account": "a",
            "user": "u",
            "warehouse": "w",
            "role": "r",
            "auth_method": "password",
            "password": "p",
        })
    )
    with pytest.raises(SystemExit):
        load_config(str(config_path))


def test_load_config_external_auth_no_password_required(tmp_path):
    config_path = tmp_path / "sfddl.json"
    config_path.write_text(
        json.dumps({
            "account": "a",
            "user": "u",
            "warehouse": "w",
            "database": "d",
            "role": "r",
            "auth_method": "external",
        })
    )
    config = load_config(str(config_path))
    assert config["auth_method"] == "external"
    assert "database" in config


def test_save_ddl_to_file_first_write(tmp_path):
    out_file = tmp_path / "fulldb.sql"
    backup_dir = tmp_path / "backups"
    content = "create or replace schema FOO;"
    result = save_ddl_to_file(content, str(out_file), str(backup_dir))
    assert result == out_file
    assert out_file.exists()
    assert out_file.read_text() == content
    assert not list(backup_dir.glob("*.sql"))  # no backup on first write


def test_save_ddl_to_file_second_write_creates_backup(tmp_path):
    out_file = tmp_path / "fulldb.sql"
    backup_dir = tmp_path / "backups"
    save_ddl_to_file("content one", str(out_file), str(backup_dir))
    save_ddl_to_file("content two", str(out_file), str(backup_dir))
    assert out_file.read_text() == "content two"
    backups = list(backup_dir.glob("fulldb_*.sql"))
    assert len(backups) == 1
    assert backups[0].read_text() == "content one"
