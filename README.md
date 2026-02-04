# Snowflake DDL Organizer

[![PyPI version](https://badge.fury.io/py/snowflake-ddl-organizer.svg)](https://badge.fury.io/py/snowflake-ddl-organizer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)

A CLI tool that extracts DDL from Snowflake databases and parses it into an organized folder structure mirroring the Snowflake UI.

## Features

- Pull complete database DDL from Snowflake using `GET_DDL()`
- Parse DDL into organized folder structure by schema and object type
- Automatic change detection - only re-parses when DDL changes
- Configurable schema inclusions/exclusions
- Automatic backup of previous DDL dumps
- Support for multiple authentication methods (password, Okta SSO, key pair)

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

Create a `config.json` file in your working directory:

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
| `--config FILE` | Path to configuration file (default: `config.json`) |
| `--no-pull` | Skip pulling from Snowflake, use existing DDL file |
| `--force-parse` | Force parsing even if DDL hasn't changed |

### Examples

```bash
# Re-parse existing DDL without connecting to Snowflake
sfddl --no-pull --force-parse

# Force a fresh parse even if no changes detected
sfddl --force-parse
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

Keep your `config.json` file secure and add it to `.gitignore` to avoid committing credentials to version control.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
