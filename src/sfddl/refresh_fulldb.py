#!/usr/bin/env python3
"""
Snowflake Database Schema Refresh Script
========================================

This script refreshes the fulldb.sql file by extracting the complete database schema
from Snowflake using the get_ddl function.

Supports multiple authentication methods:
- External browser authentication (recommended)
- Password authentication
- Key pair authentication

Requirements:
- snowflake-connector-python
- Proper Snowflake credentials and permissions

Usage:
    python refresh_fulldb.py [--config CONFIG_FILE] [--database DATABASE_NAME]
    python refresh_fulldb.py --auth external --role TEAM_CRM_ADMIN_ROLE
"""

import os
import sys
import argparse
import json
from pathlib import Path
from typing import Optional, Dict, Any
from datetime import datetime
try:
    import snowflake.connector
except ImportError:
    print("Error: snowflake-connector-python not installed.")
    print("Install with: pip install snowflake-connector-python")
    sys.exit(1)

try:
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import serialization
except ImportError:
    # cryptography is a dependency of snowflake-connector-python, so this should rarely happen
    print("Warning: cryptography library not found. Key pair authentication will not be available.")
    default_backend = None
    serialization = None

def load_config(config_file: str = "config.json") -> Dict[str, Any]:
    """Load Snowflake connection configuration from JSON file."""
    config_path = Path(config_file)
    
    if not config_path.exists():
        # Create a template config file
        template_config = {
            "account": "your_account.region",
            "user": "your_username",
            "warehouse": "your_warehouse",
            "database": "your_database",
            "schema": "your_schema",
            "role": "TEAM_CRM_ADMIN_ROLE",
            "auth_method": "external",
            "password": "your_password"
        }
        
        with open(config_path, 'w') as f:
            json.dump(template_config, f, indent=2)
        
        print(f"Created template config file: {config_path}")
        print("Please edit the file with your Snowflake credentials and run again.")
        print("\nFor external browser authentication, set:")
        print("  'auth_method': 'external'")
        print("  'role': 'TEAM_CRM_ADMIN_ROLE'")
        print("  Remove or leave empty 'password' field")
        sys.exit(1)
    
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        
        # Validate required fields based on auth method
        auth_method = config.get('auth_method', 'password')
        
        # Always require these fields
        required_fields = ['account', 'user', 'warehouse', 'database']
        
        # Only require password for password auth (not for external, okta, or keypair)
        if auth_method not in ('external', 'okta', 'keypair'):
            required_fields.append('password')
        
        missing_fields = [field for field in required_fields if field not in config or not config[field]]
        
        if missing_fields:
            print(f"Error: Missing required configuration fields: {missing_fields}")
            print(f"Please check your config file: {config_path}")
            if 'password' in missing_fields and auth_method == 'external':
                print("Note: Password is not required for external browser authentication")
            sys.exit(1)
        
        return config
    
    except json.JSONDecodeError as e:
        print(f"Error parsing config file {config_path}: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error loading config file {config_path}: {e}")
        sys.exit(1)

def connect_to_snowflake(config: Dict[str, Any]):
    """Establish connection to Snowflake."""
    try:
        # Prepare connection parameters
        conn_params = {
            'account': config['account'],
            'user': config['user'],
            'warehouse': config.get('warehouse'),
            'database': config.get('database'),
            'schema': config.get('schema'),
            'role': config.get('role', 'TEAM_CRM_ADMIN_ROLE')
        }
        
        # Handle authentication method
        auth_method = config.get('auth_method', 'password')
        
        if auth_method == 'okta':
            # Okta SSO authentication - requires okta_url in config
            okta_url = config.get('okta_url')
            if not okta_url:
                print("Error: okta_url required for Okta authentication")
                print("Set okta_url to your Okta URL, e.g., 'https://yourorg.okta.com'")
                sys.exit(1)
            print(f"Using Okta SSO authentication via {okta_url}...")
            print("A browser window will open for authentication.")
            conn_params['authenticator'] = okta_url
            
        elif auth_method == 'external':
            print("Using external browser authentication...")
            print("A browser window will open for authentication.")
            print("Please complete the authentication in your browser.")
            # For external browser auth, we need to use the authenticator parameter
            conn_params['authenticator'] = 'externalbrowser'
            
            # For US Gov Cloud, we might need additional SSL parameters
            if 'aws_us_gov' in config['account'].lower():
                print("Detected US Gov Cloud account - applying special connection parameters...")
                conn_params['insecure_mode'] = False  # Keep SSL enabled
                conn_params['client_session_keep_alive'] = True
                conn_params['client_session_keep_alive_heartbeat_frequency'] = 3600
                
                # Try with SSL verification disabled for US Gov Cloud (testing only)
                print("Attempting connection with SSL verification disabled...")
                conn_params['insecure_mode'] = True
                
        elif auth_method == 'keypair':
            # Key pair authentication using environment variables
            if serialization is None:
                print("Error: cryptography library required for key pair authentication")
                print("Install with: pip install cryptography")
                sys.exit(1)
            
            # Check for private key content or path
            private_key_content = os.environ.get('SNOWFLAKE_PRIVATE_KEY')
            private_key_path = os.environ.get('SNOWFLAKE_PRIVATE_KEY_PATH')
            
            if not private_key_content and not private_key_path:
                print("Error: No private key configured for key pair authentication")
                print("Set one of the following environment variables:")
                print("  SNOWFLAKE_PRIVATE_KEY - The private key content (PEM format)")
                print("  SNOWFLAKE_PRIVATE_KEY_PATH - Path to the private key file")
                print("")
                print("Examples:")
                print("  export SNOWFLAKE_PRIVATE_KEY=\"$(cat /path/to/rsa_key.p8)\"")
                print("  export SNOWFLAKE_PRIVATE_KEY_PATH=/path/to/rsa_key.p8")
                sys.exit(1)
            
            # Check if passphrase is provided (optional)
            passphrase = os.environ.get('SNOWFLAKE_PRIVATE_KEY_PASSPHRASE')
            
            print("Using key pair authentication...")
            if private_key_content:
                print("Private key source: environment variable (SNOWFLAKE_PRIVATE_KEY)")
            else:
                print(f"Private key source: file ({private_key_path})")
            if passphrase:
                print("Passphrase: [provided]")
            else:
                print("Passphrase: [not set - using unencrypted key]")
            
            try:
                # Load the private key from content or file
                if private_key_content:
                    # Key content provided directly in environment variable
                    key_data = private_key_content.encode()
                else:
                    # Key path provided - read from file
                    with open(private_key_path, 'rb') as key_file:
                        key_data = key_file.read()
                
                p_key = serialization.load_pem_private_key(
                    key_data,
                    password=passphrase.encode() if passphrase else None,
                    backend=default_backend()
                )
                
                # Convert to DER format for Snowflake connector
                pkb = p_key.private_bytes(
                    encoding=serialization.Encoding.DER,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption()
                )
                
                conn_params['private_key'] = pkb
                
            except FileNotFoundError:
                print(f"Error: Private key file not found: {private_key_path}")
                sys.exit(1)
            except ValueError as e:
                if "Password" in str(e) or "password" in str(e):
                    print("Error: Private key is encrypted but no passphrase provided")
                    print("Set SNOWFLAKE_PRIVATE_KEY_PASSPHRASE environment variable")
                else:
                    print(f"Error loading private key: {e}")
                sys.exit(1)
            except Exception as e:
                print(f"Error loading private key: {e}")
                sys.exit(1)
                
        elif auth_method == 'password':
            if 'password' not in config:
                print("Error: Password required for password authentication")
                sys.exit(1)
            conn_params['password'] = config['password']
            print("Using password authentication...")
        else:
            print(f"Warning: Unknown auth method '{auth_method}', using password authentication")
            if 'password' in config:
                conn_params['password'] = config['password']
        
        print(f"Attempting to connect to Snowflake account: {config['account']}")
        print(f"Connection parameters: {list(conn_params.keys())}")
        
        # Establish connection
        conn = snowflake.connector.connect(**conn_params)
        
        print(f"Successfully connected to Snowflake account: {config['account']}")
        print(f"Connected as user: {config['user']}")
        print(f"Using role: {conn_params.get('role', 'default')}")
        
        return conn
    
    except Exception as e:
        print(f"Error connecting to Snowflake: {e}")
        print("\nTroubleshooting tips:")
        print("- Check your account URL format (e.g., 'org-account.region')")
        print("- Verify your username and role permissions")
        print("- For external auth, ensure you can access the browser")
        print("- For keypair auth, verify the public key is registered with your Snowflake user")
        print("- For keypair auth, check SNOWFLAKE_PRIVATE_KEY_PATH points to a valid key file")
        print("- Check network connectivity and firewall settings")
        print("- US Gov Cloud may require special network access")
        print("- Contact your network administrator if SSL issues persist")
        print("- SSL certificate issues may require network/firewall configuration")
        sys.exit(1)

def get_database_ddl(conn, database_name: str) -> str:
    """Extract complete database DDL using get_ddl function."""
    try:
        cursor = conn.cursor()
        
        # Set the database context
        cursor.execute(f"USE DATABASE {database_name}")
        print(f"Using database: {database_name}")
        
        # Get the complete database DDL
        print("Extracting database schema...")
        print("This may take a while for large databases...")
        
        cursor.execute(f"SELECT GET_DDL('DATABASE', '{database_name}')")
        
        result = cursor.fetchone()
        if result and result[0]:
            ddl_content = result[0]
            print(f"Successfully extracted DDL (size: {len(ddl_content)} bytes)")
            return ddl_content
        else:
            print("Error: No DDL content returned from get_ddl function")
            print("This may indicate insufficient permissions or database access issues")
            sys.exit(1)
    
    except Exception as e:
        print(f"Error extracting database DDL: {e}")
        print("\nCommon causes:")
        print("- Insufficient permissions on the database")
        print("- Database doesn't exist or is not accessible")
        print("- Role doesn't have USAGE privilege on database")
        print("- Network or connection issues")
        sys.exit(1)
    finally:
        if 'cursor' in locals():
            cursor.close()

def save_ddl_to_file(ddl_content: str, output_file: str = "fulldb.sql", backup_dir: str = "backups"):
    """Save the DDL content to a file."""
    try:
        output_path = Path(output_file)
        
        # Create parent directory if it doesn't exist
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Create backup if file exists
        if output_path.exists():
            # Create backups directory if it doesn't exist
            backups_dir = Path(backup_dir)
            backups_dir.mkdir(exist_ok=True)
            
            # Generate timestamp for backup filename
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Create backup filename with timestamp
            backup_filename = f"{output_path.stem}_{timestamp}.sql"
            backup_path = backups_dir / backup_filename
            
            # Move existing file to backup
            output_path.rename(backup_path)
            print(f"Created backup: {backup_path}")
        
        # Write new DDL content
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(ddl_content)
        
        print(f"Successfully saved DDL to: {output_path}")
        print(f"File size: {len(ddl_content)} bytes")
        
        return output_path
    
    except Exception as e:
        print(f"Error saving DDL to file: {e}")
        sys.exit(1)

def _standalone_main():
    """Standalone main function for running refresh_fulldb.py directly."""
    parser = argparse.ArgumentParser(
        description="Refresh fulldb.sql from Snowflake database schema"
    )
    parser.add_argument(
        '--config', 
        default='snowflake_config.json',
        help='Path to Snowflake configuration file (default: snowflake_config.json)'
    )
    parser.add_argument(
        '--database',
        help='Snowflake database name (overrides config file)'
    )
    parser.add_argument(
        '--output',
        default='fulldb.sql',
        help='Output file name (default: fulldb.sql)'
    )
    parser.add_argument(
        '--auth',
        choices=['external', 'password', 'keypair'],
        help='Authentication method (overrides config file)'
    )
    parser.add_argument(
        '--role',
        default='TEAM_CRM_ADMIN_ROLE',
        help='Snowflake role to use (default: TEAM_CRM_ADMIN_ROLE)'
    )
    
    args = parser.parse_args()
    
    print("Snowflake Database Schema Refresh")
    print("=" * 40)
    
    # Load configuration
    config = load_config(args.config)
    
    # Override config with command line arguments
    if args.database:
        config['database'] = args.database
    if args.auth:
        config['auth_method'] = args.auth
    if args.role:
        config['role'] = args.role
    
    # Connect to Snowflake
    conn = connect_to_snowflake(config)
    
    try:
        # Extract database DDL
        ddl_content = get_database_ddl(conn, config['database'])
        
        # Save to file
        output_path = save_ddl_to_file(ddl_content, args.output)
        
        print("\n" + "=" * 40)
        print("REFRESH COMPLETE")
        print("=" * 40)
        print(f"Database schema has been refreshed and saved to: {output_path}")
        print("You can now run db_parser.py to organize the objects by schema.")
        
    finally:
        conn.close()
        print("Snowflake connection closed.")

if __name__ == "__main__":
    _standalone_main()
