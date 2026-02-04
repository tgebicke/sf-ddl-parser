#!/usr/bin/env python3
"""
Snowflake DDL Organizer CLI
============================

A CLI tool that pulls DDL from Snowflake and parses it into
an organized folder structure mirroring the Snowflake UI.

Usage:
    sfddl                          # Pull and parse with default sfddl.json
    sfddl --config other.json      # Use custom config file
    sfddl --no-pull                # Skip Snowflake, parse existing DDL file
    sfddl --force-parse            # Force parse even if no changes detected
    sfddl --no-pull --force-parse  # Re-parse existing DDL file
"""

import argparse
import hashlib
from pathlib import Path

from sfddl.refresh_fulldb import load_config, connect_to_snowflake, get_database_ddl, save_ddl_to_file
from sfddl.ddl_parser import parse_sql_by_database_and_schema


def file_matches_content(filepath: Path, content: str) -> bool:
    """
    Check if the existing file content matches the new content using MD5 hash.
    Returns True if they match (no changes), False otherwise.
    """
    if not filepath.exists():
        return False
    
    existing_hash = hashlib.md5(filepath.read_bytes()).hexdigest()
    new_hash = hashlib.md5(content.encode('utf-8')).hexdigest()
    
    return existing_hash == new_hash


def main():
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(
        description="Snowflake DDL Organizer - Extract and organize database DDL"
    )
    parser.add_argument(
        '--config',
        default='sfddl.json',
        help='Path to configuration file (default: sfddl.json)'
    )
    parser.add_argument(
        '--no-pull',
        action='store_true',
        dest='no_pull',
        help='Skip pulling DDL from Snowflake, use existing file'
    )
    parser.add_argument(
        '--force-parse',
        action='store_true',
        dest='force_parse',
        help='Force parsing even if DDL has not changed'
    )
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Snowflake DDL Organizer")
    print("=" * 60)
    
    # Load configuration
    config = load_config(args.config)
    
    # Extract config values with defaults
    sql_file = config.get('sql_file', 'full_db/fulldb.sql')
    output_dir = config.get('output_dir', 'databases')
    backup_dir = config.get('backup_dir', 'backups')
    database_name_override = config.get('database_name_override')
    include_schemas = config.get('include_schemas', [])
    exclude_schemas = config.get('exclude_schemas', [])
    
    print(f"\nConfiguration loaded from: {args.config}")
    print(f"  Database: {config['database']}")
    print(f"  SQL file: {sql_file}")
    print(f"  Output dir: {output_dir}")
    if include_schemas:
        print(f"  Including schemas: {', '.join(include_schemas)}")
    elif exclude_schemas:
        print(f"  Excluding schemas: {', '.join(exclude_schemas)}")
    if args.no_pull:
        print("  Mode: --no-pull (using existing DDL file)")
    if args.force_parse:
        print("  Mode: --force-parse (skipping change detection)")
    
    sql_file_path = Path(sql_file)
    
    # Step 1: Pull DDL from Snowflake (unless --no-pull)
    if args.no_pull:
        print("\n" + "-" * 60)
        print("Step 1: Skipping Snowflake pull (--no-pull)")
        print("-" * 60)
        
        if not sql_file_path.exists():
            print(f"\nError: DDL file not found: {sql_file}")
            print("Cannot use --no-pull without an existing DDL file.")
            return
        
        print(f"Reading existing DDL from: {sql_file}")
        ddl_content = sql_file_path.read_text(encoding='utf-8')
        print(f"Loaded DDL (size: {len(ddl_content)} bytes)")
    else:
        print("\n" + "-" * 60)
        print("Step 1: Pulling DDL from Snowflake")
        print("-" * 60)
        
        conn = connect_to_snowflake(config)
        
        try:
            ddl_content = get_database_ddl(conn, config['database'])
        finally:
            conn.close()
            print("Snowflake connection closed.")
    
    # Step 2: Check for changes (unless --force-parse or --no-pull)
    if not args.force_parse and not args.no_pull:
        print("\n" + "-" * 60)
        print("Step 2: Checking for changes")
        print("-" * 60)
        
        if file_matches_content(sql_file_path, ddl_content):
            print("\nNo changes detected in database DDL.")
            print("The existing DDL file matches the current database state.")
            print("Skipping parsing step. Use --force-parse to override.")
            print("\n" + "=" * 60)
            print("COMPLETE - No changes found")
            print("=" * 60)
            return
        
        # Changes detected - save new DDL
        print("\nChanges detected! Saving new DDL...")
        save_ddl_to_file(ddl_content, sql_file, backup_dir)
    elif args.force_parse and not args.no_pull:
        print("\n" + "-" * 60)
        print("Step 2: Skipping change detection (--force-parse)")
        print("-" * 60)
        save_ddl_to_file(ddl_content, sql_file, backup_dir)
    else:
        print("\n" + "-" * 60)
        print("Step 2: Using existing DDL file")
        print("-" * 60)
    
    # Step 3: Parse the DDL
    print("\n" + "-" * 60)
    print("Step 3: Parsing DDL into folder structure")
    print("-" * 60)
    
    parse_sql_by_database_and_schema(
        ddl_content,
        database_name_override=database_name_override,
        output_dir_override=output_dir,
        include_schemas=include_schemas,
        exclude_schemas=exclude_schemas
    )
    
    print("\n" + "=" * 60)
    print("COMPLETE - DDL parsed successfully")
    print("=" * 60)
    if not args.no_pull:
        print(f"DDL saved to: {sql_file}")
    print(f"Parsed structure in: {output_dir}/")


if __name__ == "__main__":
    main()
