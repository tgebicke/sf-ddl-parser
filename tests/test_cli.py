"""Tests for sfddl.cli (file_matches_content, main with --no-pull)."""

import sys
import pytest
from pathlib import Path

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
