"""Tests for sfddl.refresh_fulldb (load_config, save_ddl_to_file, connect_to_snowflake, get_database_ddl)."""

import json
import pytest
from unittest.mock import MagicMock, patch

from sfddl.refresh_fulldb import load_config, save_ddl_to_file, connect_to_snowflake, get_database_ddl


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


# --- connect_to_snowflake ---

BASE_CONFIG = {
    "account": "test.account",
    "user": "testuser",
    "warehouse": "WH",
    "database": "TEST_DB",
    "role": "ROLE",
}


def test_connect_password_auth():
    config = {**BASE_CONFIG, "auth_method": "password", "password": "secret"}
    mock_conn = MagicMock()
    with patch("snowflake.connector.connect", return_value=mock_conn) as mock_connect:
        result = connect_to_snowflake(config)
    assert result is mock_conn
    call_kwargs = mock_connect.call_args.kwargs
    assert call_kwargs["password"] == "secret"


def test_connect_password_missing_raises(capsys):
    config = {**BASE_CONFIG, "auth_method": "password"}  # no password key
    with pytest.raises(SystemExit):
        connect_to_snowflake(config)


def test_connect_external_auth():
    config = {**BASE_CONFIG, "auth_method": "external"}
    mock_conn = MagicMock()
    with patch("snowflake.connector.connect", return_value=mock_conn) as mock_connect:
        result = connect_to_snowflake(config)
    assert result is mock_conn
    call_kwargs = mock_connect.call_args.kwargs
    assert call_kwargs["authenticator"] == "externalbrowser"


def test_connect_external_auth_gov_cloud():
    config = {**BASE_CONFIG, "account": "myorg-aws_us_gov-myaccount", "auth_method": "external"}
    mock_conn = MagicMock()
    with patch("snowflake.connector.connect", return_value=mock_conn) as mock_connect:
        result = connect_to_snowflake(config)
    assert result is mock_conn
    call_kwargs = mock_connect.call_args.kwargs
    assert call_kwargs.get("client_session_keep_alive") is True
    assert call_kwargs.get("insecure_mode") is False


def test_connect_okta_auth():
    config = {**BASE_CONFIG, "auth_method": "okta", "okta_url": "https://myorg.okta.com"}
    mock_conn = MagicMock()
    with patch("snowflake.connector.connect", return_value=mock_conn) as mock_connect:
        result = connect_to_snowflake(config)
    assert result is mock_conn
    call_kwargs = mock_connect.call_args.kwargs
    assert call_kwargs["authenticator"] == "https://myorg.okta.com"


def test_connect_okta_auth_missing_url():
    config = {**BASE_CONFIG, "auth_method": "okta"}  # no okta_url
    with pytest.raises(SystemExit):
        connect_to_snowflake(config)


def test_connect_keypair_auth_env_var(monkeypatch):
    config = {**BASE_CONFIG, "auth_method": "keypair"}
    monkeypatch.setenv("SNOWFLAKE_PRIVATE_KEY", "FAKE_PEM_CONTENT")
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY_PATH", raising=False)
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE", raising=False)

    mock_key = MagicMock()
    mock_key.private_bytes.return_value = b"fake_der"
    mock_conn = MagicMock()

    import sfddl.refresh_fulldb as rfdb
    with patch.object(rfdb.serialization, "load_pem_private_key", return_value=mock_key), \
         patch("sfddl.refresh_fulldb.default_backend", return_value=None), \
         patch("snowflake.connector.connect", return_value=mock_conn):
        result = connect_to_snowflake(config)

    assert result is mock_conn


def test_connect_keypair_auth_file(tmp_path, monkeypatch):
    key_file = tmp_path / "rsa_key.p8"
    key_file.write_bytes(b"FAKE_PEM_CONTENT")

    config = {**BASE_CONFIG, "auth_method": "keypair"}
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY", raising=False)
    monkeypatch.setenv("SNOWFLAKE_PRIVATE_KEY_PATH", str(key_file))
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE", raising=False)

    mock_key = MagicMock()
    mock_key.private_bytes.return_value = b"fake_der"
    mock_conn = MagicMock()

    import sfddl.refresh_fulldb as rfdb
    with patch.object(rfdb.serialization, "load_pem_private_key", return_value=mock_key), \
         patch("sfddl.refresh_fulldb.default_backend", return_value=None), \
         patch("snowflake.connector.connect", return_value=mock_conn):
        result = connect_to_snowflake(config)

    assert result is mock_conn


def test_connect_keypair_missing_key(monkeypatch):
    config = {**BASE_CONFIG, "auth_method": "keypair"}
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY", raising=False)
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY_PATH", raising=False)
    with pytest.raises(SystemExit):
        connect_to_snowflake(config)


def test_connect_keypair_file_not_found(tmp_path, monkeypatch):
    config = {**BASE_CONFIG, "auth_method": "keypair"}
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY", raising=False)
    monkeypatch.setenv("SNOWFLAKE_PRIVATE_KEY_PATH", str(tmp_path / "missing.p8"))
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE", raising=False)

    import sfddl.refresh_fulldb as rfdb
    with patch.object(rfdb.serialization, "load_pem_private_key", side_effect=FileNotFoundError):
        with pytest.raises(SystemExit):
            connect_to_snowflake(config)


def test_connect_keypair_bad_passphrase(monkeypatch):
    config = {**BASE_CONFIG, "auth_method": "keypair"}
    monkeypatch.setenv("SNOWFLAKE_PRIVATE_KEY", "FAKE_PEM")
    monkeypatch.delenv("SNOWFLAKE_PRIVATE_KEY_PATH", raising=False)
    monkeypatch.setenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE", "wrongpass")

    import sfddl.refresh_fulldb as rfdb
    with patch.object(rfdb.serialization, "load_pem_private_key",
                      side_effect=ValueError("Password was given but private key is not encrypted")):
        with pytest.raises(SystemExit):
            connect_to_snowflake(config)


def test_connect_unknown_auth_with_password():
    config = {**BASE_CONFIG, "auth_method": "magic_sso", "password": "fallback"}
    mock_conn = MagicMock()
    with patch("snowflake.connector.connect", return_value=mock_conn) as mock_connect:
        result = connect_to_snowflake(config)
    assert result is mock_conn
    assert mock_connect.call_args.kwargs.get("password") == "fallback"


def test_connect_failure_raises():
    config = {**BASE_CONFIG, "auth_method": "password", "password": "bad"}
    with patch("snowflake.connector.connect", side_effect=Exception("auth failed")):
        with pytest.raises(SystemExit):
            connect_to_snowflake(config)


# --- get_database_ddl ---


def test_get_database_ddl_success():
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchone.return_value = ("CREATE DATABASE TEST_DB;",)

    result = get_database_ddl(mock_conn, "TEST_DB")

    assert result == "CREATE DATABASE TEST_DB;"
    mock_cursor.close.assert_called_once()


def test_get_database_ddl_empty_result():
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchone.return_value = (None,)

    with pytest.raises(SystemExit):
        get_database_ddl(mock_conn, "TEST_DB")

    mock_cursor.close.assert_called_once()


def test_get_database_ddl_none_result():
    mock_conn = MagicMock()
    mock_cursor = MagicMock()
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchone.return_value = None

    with pytest.raises(SystemExit):
        get_database_ddl(mock_conn, "TEST_DB")


def test_get_database_ddl_exception():
    mock_conn = MagicMock()
    mock_conn.cursor.side_effect = Exception("connection lost")

    with pytest.raises(SystemExit):
        get_database_ddl(mock_conn, "TEST_DB")
