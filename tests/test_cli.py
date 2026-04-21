"""Tests for sfddl.cli (file_matches_content, main with --no-pull)."""

import json
import sys
import pytest
from pathlib import Path
from unittest.mock import MagicMock

from sfddl.cli import file_matches_content, main


def test_file_matches_content_same(tmp_path):
    f = tmp_path / "f.sql"
    f.write_text("same content")
    assert file_matches_content(f, "same content") is True


def test_file_matches_content_different(tmp_path):
    f = tmp_path / "f.sql"
    f.write_text("original")
    assert file_matches_content(f, "different") is False


def test_file_matches_content_missing_file(tmp_path):
    assert file_matches_content(tmp_path / "nonexistent.sql", "any") is False


def test_main_no_pull_success(minimal_ddl, valid_config_dict, tmp_path, capsys, monkeypatch):
    sql_file = Path(valid_config_dict["sql_file"])
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    sql_file.write_text(minimal_ddl)
    config_path = tmp_path / "sfddl.json"
    config_path.write_text(__import__("json").dumps(valid_config_dict, indent=2))

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path), "--no-pull"])
    main()

    out = capsys.readouterr()
    assert "COMPLETE" in out.out
    assert "Step 3" in out.out
    output_dir = Path(valid_config_dict["output_dir"])
    assert output_dir.exists()
    assert list(output_dir.rglob("*.sql"))


def test_main_no_pull_missing_ddl_file(valid_config_dict, tmp_path, capsys, monkeypatch):
    valid_config_dict["sql_file"] = str(tmp_path / "missing.sql")
    config_path = tmp_path / "sfddl.json"
    config_path.write_text(__import__("json").dumps(valid_config_dict, indent=2))

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path), "--no-pull"])
    main()

    out = capsys.readouterr()
    assert "DDL file not found" in out.out or "not found" in out.out
    output_dir = Path(valid_config_dict["output_dir"])
    assert not output_dir.exists() or not list(output_dir.rglob("*.sql"))


def test_main_missing_config(tmp_path, monkeypatch):
    missing_config = tmp_path / "missing_config.json"
    assert not missing_config.exists()
    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(missing_config)])
    with pytest.raises(SystemExit):
        main()


# --- Pull flow (Snowflake connection mocked) ---


def _write_config(tmp_path, config_dict):
    config_path = tmp_path / "sfddl.json"
    config_path.write_text(json.dumps(config_dict))
    return config_path


def test_main_pull_no_change_detected(valid_config_dict, minimal_ddl, tmp_path, capsys, monkeypatch):
    """When DDL matches what's on disk, parsing is skipped."""
    sql_file = Path(valid_config_dict["sql_file"])
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    sql_file.write_text(minimal_ddl)  # same content Snowflake would return

    config_path = _write_config(tmp_path, valid_config_dict)
    mock_conn = MagicMock()
    monkeypatch.setattr("sfddl.cli.connect_to_snowflake", lambda c: mock_conn)
    monkeypatch.setattr("sfddl.cli.get_database_ddl", lambda conn, db: minimal_ddl)

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path)])
    main()

    out = capsys.readouterr().out
    assert "No changes detected" in out
    assert "COMPLETE" in out
    mock_conn.close.assert_called_once()


def test_main_pull_change_detected(valid_config_dict, minimal_ddl, tmp_path, capsys, monkeypatch):
    """When DDL differs from disk, new DDL is saved and parsed."""
    sql_file = Path(valid_config_dict["sql_file"])
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    sql_file.write_text("old content")  # different from what Snowflake returns

    config_path = _write_config(tmp_path, valid_config_dict)
    mock_conn = MagicMock()
    monkeypatch.setattr("sfddl.cli.connect_to_snowflake", lambda c: mock_conn)
    monkeypatch.setattr("sfddl.cli.get_database_ddl", lambda conn, db: minimal_ddl)

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path)])
    main()

    out = capsys.readouterr().out
    assert "Changes detected" in out
    assert "COMPLETE" in out
    assert "DDL saved to" in out
    mock_conn.close.assert_called_once()


def test_main_pull_force_parse(valid_config_dict, minimal_ddl, tmp_path, capsys, monkeypatch):
    """--force-parse skips change detection and saves + parses unconditionally."""
    config_path = _write_config(tmp_path, valid_config_dict)
    mock_conn = MagicMock()
    monkeypatch.setattr("sfddl.cli.connect_to_snowflake", lambda c: mock_conn)
    monkeypatch.setattr("sfddl.cli.get_database_ddl", lambda conn, db: minimal_ddl)

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path), "--force-parse"])
    main()

    out = capsys.readouterr().out
    assert "Skipping change detection" in out
    assert "force-parse" in out.lower() or "--force-parse" in out
    assert "COMPLETE" in out
    mock_conn.close.assert_called_once()


# --- include/exclude schema print paths ---


def test_main_no_pull_with_include_schemas(valid_config_dict, minimal_ddl, tmp_path, capsys, monkeypatch):
    valid_config_dict["include_schemas"] = ["FOO"]
    sql_file = Path(valid_config_dict["sql_file"])
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    sql_file.write_text(minimal_ddl)
    config_path = _write_config(tmp_path, valid_config_dict)

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path), "--no-pull"])
    main()

    out = capsys.readouterr().out
    assert "Including schemas" in out
    assert "COMPLETE" in out


def test_main_no_pull_with_exclude_schemas(valid_config_dict, minimal_ddl, tmp_path, capsys, monkeypatch):
    valid_config_dict["exclude_schemas"] = ["BAR"]
    sql_file = Path(valid_config_dict["sql_file"])
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    sql_file.write_text(minimal_ddl)
    config_path = _write_config(tmp_path, valid_config_dict)

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path), "--no-pull"])
    main()

    out = capsys.readouterr().out
    assert "Excluding schemas" in out
    assert "COMPLETE" in out


def test_main_no_pull_restore_sp_formatting_flag(valid_config_dict, minimal_ddl, tmp_path, capsys, monkeypatch):
    sql_file = Path(valid_config_dict["sql_file"])
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    sql_file.write_text(minimal_ddl)
    config_path = _write_config(tmp_path, valid_config_dict)

    monkeypatch.setattr(sys, "argv", ["sfddl", "--config", str(config_path), "--no-pull", "--restore-sp-formatting"])
    main()

    out = capsys.readouterr().out
    assert "restore-sp-formatting" in out
    assert "COMPLETE" in out
