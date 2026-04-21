# Snowflake DDL Organizer

[![PyPI version](https://badge.fury.io/py/snowflake-ddl-organizer.svg)](https://badge.fury.io/py/snowflake-ddl-organizer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)

A CLI tool that extracts your entire Snowflake database DDL in a single API call and organizes it into a clean, browsable folder structure — one file per object, mirroring the Snowflake UI hierarchy.

## Features

### Lightning-Fast Extraction via `GET_DDL()`
Rather than making individual API calls for each object in your database, `sfddl` uses Snowflake's `GET_DDL()` to retrieve the complete database schema in **one round trip**. For large databases with hundreds or thousands of objects, this is orders of magnitude faster than object-by-object approaches.

### True Sync — Deletions Included
`sfddl` doesn't just add or update files — it **prunes files for objects that no longer exist** in Snowflake. Drop a table, rename a view, or delete a procedure, and the corresponding file disappears on the next run. Your local folder is always an accurate mirror of what's in Snowflake, not an ever-growing accumulation.

### AI and Agent Ready
With your entire database DDL organized as individual files on disk, **AI coding assistants and LLM agents can reason about your full schema without hitting Snowflake at all**. Feed a schema folder to your agent, ask questions about table relationships, or use it as context when generating SQL — everything is already local, structured, and readable.

### Smart Change Detection
`sfddl` computes an MD5 hash of the DDL before and after each pull. If nothing changed in Snowflake, **parsing is skipped entirely**. Only real changes trigger a re-parse, keeping runs fast on unchanged databases.

### Multiple Object Types Supported
Tables, views, procedures, functions, sequences, streams, pipes, tasks, stages, file formats, and many more — all organized into typed subfolders per schema.

### Overloaded Procedure and Function Support
Procedures and functions with the same name but different argument signatures are **disambiguated automatically** using types-only argument signatures in the filename (e.g., `MY_PROC(VARCHAR,NUMBER).sql`). No overloads are lost or overwritten.

### Clean, Readable Procedure Bodies
Snowflake's `GET_DDL()` encodes procedure and function bodies using escaped single-quotes. The optional `--restore-sp-formatting` flag converts them back to the familiar `$$`-delimited format, making stored procedures readable and ready for version control.

### Flexible Schema Filtering
Include or exclude specific schemas by name — useful for ignoring `INFORMATION_SCHEMA`, focusing on a single team's schemas, or excluding schemas you don't own.

### Multiple Authentication Methods
Password, Okta SSO, external browser, and RSA key pair authentication are all supported out of the box.

### Automatic Backups
Every DDL pull is backed up with a timestamp before overwriting, so you always have a history of prior snapshots.

## Installation

### From PyPI

```bash
pip install snowflake-ddl-organizer
```

### From Source

```bash
git clone https://github.com/YOUR_USERNAME/snowflake-ddl-organizer.git
cd snowflake-ddl-organizer
pip install -e .
```

## Configuration

Create a `sfddl.json` file in your working directory (e.g. copy from `sfddl.sample.json`):

```json
{
  "account": "your-account-identifier",
  "user": "YOUR_USERNAME",
  "warehouse": "COMPUTE_WH",
  "database": "YOUR_DATABASE",
  "role": "YOUR_ROLE",
  "auth_method": "password",
  "password": "your_password",
  "sql_file": "full_db/fulldb.sql",
  "output_dir": "databases",
  "backup_dir": "backups",
  "database_name_override": null,
  "include_schemas": [],
  "exclude_schemas": ["INFORMATION_SCHEMA", "PUBLIC"]
}
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `account` | Snowflake account identifier (org-account format) | Required |
| `user` | Snowflake username | Required |
| `warehouse` | Snowflake warehouse | Required |
| `database` | Database to extract DDL from | Required |
| `role` | Snowflake role to use | Required |
| `auth_method` | Authentication method: `password`, `okta`, `external`, or `keypair` | `password` |
| `password` | Password (for password auth) | - |
| `okta_url` | Okta SSO URL (for okta auth) | - |
| Environment: `SNOWFLAKE_PRIVATE_KEY` | RSA private key content in PEM format (for keypair auth) | - |
| Environment: `SNOWFLAKE_PRIVATE_KEY_PATH` | Path to RSA private key file (for keypair auth) | - |
| Environment: `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` | Passphrase for encrypted private key (optional) | - |
| `sql_file` | Path to save the DDL dump | `full_db/fulldb.sql` |
| `output_dir` | Directory for parsed structure | `databases` |
| `backup_dir` | Directory for DDL backups | `backups` |
| `database_name_override` | Override auto-detected database name | `null` |
| `include_schemas` | Array of schema names to include (takes precedence over exclude_schemas) | `[]` |
| `exclude_schemas` | Array of schema names to skip (ignored if include_schemas is set) | `[]` |

## Usage

### Basic Usage

```bash
# Pull DDL from Snowflake and parse it
sfddl

# Use a custom config file
sfddl --config my_config.json
```

### CLI Options

| Flag | Description |
|------|-------------|
| `--config FILE` | Path to configuration file (default: `sfddl.json`) |
| `--no-pull` | Skip pulling from Snowflake, use existing DDL file |
| `--force-parse` | Force parsing even if DDL hasn't changed |
| `--restore-sp-formatting` | Restore procedure and function bodies from Snowflake's single-quote encoding to `$$`-delimited format |

### Examples

```bash
# Re-parse existing DDL without connecting to Snowflake
sfddl --no-pull --force-parse

# Force a fresh parse even if no changes detected
sfddl --force-parse

# Restore procedure bodies to $$-delimited format
sfddl --restore-sp-formatting

# Re-parse existing DDL and restore procedure formatting
sfddl --no-pull --restore-sp-formatting
```

### Stored Procedure and Function Formatting

Snowflake's `GET_DDL()` encodes procedure and function bodies as single-quoted strings with escaped internal quotes (`''`), regardless of how they were originally authored:

```sql
-- Snowflake DDL output
CREATE OR REPLACE PROCEDURE MY_PROC()
RETURNS VARCHAR
LANGUAGE SQL
AS 'BEGIN
    SELECT ''hello'';
END';
```

The `--restore-sp-formatting` flag converts these back to the more readable `$$`-delimited format:

```sql
-- Restored format
CREATE OR REPLACE PROCEDURE MY_PROC()
RETURNS VARCHAR
LANGUAGE SQL
AS $$
BEGIN
    SELECT 'hello';
END
$$;
```

## Output Structure

The parser creates a folder structure organized by schema and object type:

```
databases/
└── YOUR_DATABASE/
    ├── SCHEMA_ONE/
    │   ├── schemas/
    │   │   └── SCHEMA_ONE.sql
    │   ├── tables/
    │   │   ├── TABLE_A.sql
    │   │   └── TABLE_B.sql
    │   ├── views/
    │   │   └── VIEW_A.sql
    │   ├── procedures/
    │   │   └── PROC_A.sql
    │   └── functions/
    │       └── FUNC_A.sql
    └── SCHEMA_TWO/
        └── ...
```

### Supported Object Types

- Tables (including transient, temporary, external)
- Views (including secure, materialized)
- Procedures
- Functions
- Sequences
- Streams
- Pipes
- Tasks
- Stages
- File Formats
- And more...

## Authentication

### Password Authentication

Set `auth_method` to `password` and provide your password:

```json
{
  "auth_method": "password",
  "password": "your_password"
}
```

### Okta SSO Authentication

Set `auth_method` to `okta` and provide your Okta URL:

```json
{
  "auth_method": "okta",
  "okta_url": "https://yourorg.okta.com"
}
```

A browser window will open for authentication.

### External Browser Authentication

Set `auth_method` to `external`:

```json
{
  "auth_method": "external"
}
```

A browser window will open for authentication.

### Key Pair Authentication

Set `auth_method` to `keypair` and configure environment variables:

```json
{
  "auth_method": "keypair"
}
```

Then set the required environment variables. You can provide either the key content directly or a path to the key file:

**Option 1: Private key content directly**

```bash
# The private key content in PEM format
export SNOWFLAKE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqh...
-----END PRIVATE KEY-----"

# Optional: Passphrase if your private key is encrypted
export SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=your-passphrase
```

**Option 2: Path to private key file**

```bash
# Path to your RSA private key file
export SNOWFLAKE_PRIVATE_KEY_PATH=/path/to/rsa_key.p8

# Optional: Passphrase if your private key is encrypted
export SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=your-passphrase
```

Note: If both `SNOWFLAKE_PRIVATE_KEY` and `SNOWFLAKE_PRIVATE_KEY_PATH` are set, the key content (`SNOWFLAKE_PRIVATE_KEY`) takes precedence.

#### Generating RSA Key Pairs for Snowflake

1. Generate an encrypted private key:

```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8
```

2. Generate the public key:

```bash
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

3. Register the public key with your Snowflake user:

```sql
ALTER USER your_username SET RSA_PUBLIC_KEY='MIIBIjANBgkqh...';
```

Note: Copy the public key contents without the `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----` headers.

## Security Note

Keep your `sfddl.json` file secure and add it to `.gitignore` to avoid committing credentials to version control.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
