import os
import re
import argparse
import hashlib
from pathlib import Path

def prune_removed_files(database_dir: Path, expected_paths: set[Path], dry_run: bool = False) -> dict:
    """
    Remove files under `database_dir` that are not present in `expected_paths`.
    Returns a summary dict with counts.
    """
    removed_files = 0
    removed_dirs = 0

    # Normalize paths for comparison
    expected_paths = {p.resolve() for p in expected_paths}
    database_dir = database_dir.resolve()

    # 1) Delete stray files
    for fs_path in database_dir.rglob("*.sql"):
        if fs_path.resolve() not in expected_paths:
            if dry_run:
                print(f"[DRY-RUN] Would remove: {fs_path}")
            else:
                try:
                    fs_path.unlink()
                    removed_files += 1
                    print(f"    ✂ removed: {fs_path.relative_to(database_dir)}")
                except Exception as e:
                    print(f"    ⚠ could not remove {fs_path}: {e}")

    # 2) Remove empty directories (deepest-first)
    # Walk bottom-up so we only try to remove a dir after children considered
    for dir_path in sorted({p.parent for p in database_dir.rglob("*")}, key=lambda p: len(p.parts), reverse=True):
        if dir_path == database_dir:
            continue
        # If directory is empty after file removals, delete it
        if not any(dir_path.iterdir()):
            if dry_run:
                print(f"[DRY-RUN] Would remove empty dir: {dir_path}")
            else:
                try:
                    dir_path.rmdir()
                    removed_dirs += 1
                    # Optional: print(f"    🗑️ removed empty dir: {dir_path.relative_to(database_dir)}")
                except Exception as e:
                    print(f"    ⚠ could not rmdir {dir_path}: {e}")

    return {"removed_files": removed_files, "removed_dirs": removed_dirs}


def extract_multiline_comments(sql_content: str) -> tuple[str, dict[str, str]]:
    """
    Extract multi-line comments (/* ... */) from SQL content using regex and replace with placeholders.
    Returns (modified_content, comments_dict) where comments_dict maps hash to original comment.
    Extracts ALL comments (including those inside procedure/function bodies) to prevent
    CREATE statements inside comments from being parsed.
    """
    comments = {}
    
    # Pattern to match multi-line comments (non-greedy, with DOTALL to match across lines)
    # Use a more explicit pattern that handles newlines
    comment_pattern = r'/\*[\s\S]*?\*/'
    
    # Find all comment matches
    matches = list(re.finditer(comment_pattern, sql_content))
    
    # Process matches in reverse order to preserve positions when replacing
    # Extract ALL comments (both inside and outside strings) to prevent CREATE statements
    # in comments from being parsed
    result = sql_content
    for match in reversed(matches):
        start_pos = match.start()
        end_pos = match.end()
        comment_text = match.group(0)
        
        # Extract all comments regardless of whether they're in strings
        # This prevents CREATE statements inside comments from being parsed
        comment_hash = hashlib.md5(comment_text.encode('utf-8')).hexdigest()[:8]
        # Store comment
        comments[comment_hash] = comment_text
        # Replace with placeholder
        placeholder = f"<comment={comment_hash}/>"
        result = result[:start_pos] + placeholder + result[end_pos:]
    
    return result, comments


def restore_comments(content: str, comments: dict[str, str]) -> str:
    """
    Restore multi-line comments by replacing placeholders with original comments.
    """
    result = content
    for comment_hash, comment_text in comments.items():
        placeholder = f"<comment={comment_hash}/>"
        result = result.replace(placeholder, comment_text)
    return result


def get_database_name(sql_content):
    """Extract the database name from the SQL content."""
    # Look for database name in various patterns
    patterns = [
        # Pattern for CREATE DATABASE statements (highest priority)
        r'create\s+(?:or\s+replace\s+)?database\s+([A-Za-z0-9_]+)',
        # Pattern for get_ddl output: "database_name" (most common for Snowflake)
        r'"([A-Za-z0-9_]+)"',
        # Pattern for Snowflake get_ddl with database context: database_name.schema_name
        r'([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)',
        # Pattern for USE DATABASE statements
        r'USE\s+(?:DATABASE\s+)?([A-Za-z0-9_]+)',
        # Pattern for database qualification in object names (database.schema.object)
        r'([A-Za-z0-9_]+)\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+',
        # Pattern for schema statements that might include database context
        r'create\s+or\s+replace\s+schema\s+([A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)?)',
        # Pattern for Snowflake object creation with database qualification
        r'create\s+(?:or\s+replace\s+)?(?:table|view|procedure|function)\s+([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, sql_content, re.IGNORECASE)
        if match:
            if len(match.groups()) == 1:
                db_name = match.group(1)
            else:
                # For patterns with multiple groups, first group is usually database
                db_name = match.group(1)
            
            # If we found a qualified name (database.schema), extract just the database part
            if '.' in db_name:
                db_name = db_name.split('.')[0]
            return db_name
    
    # Default database name if none found
    return 'default_database'

def get_schema_name(schema_statement):
    """Extract the schema name from a CREATE SCHEMA statement."""
    # Pattern to match: create or replace schema SCHEMA_NAME [COMMENT='...']
    pattern = r'create\s+or\s+replace\s+schema\s+([A-Za-z0-9_]+)'
    match = re.search(pattern, schema_statement, re.IGNORECASE)
    if match:
        return match.group(1)
    return None

def get_object_type(first_line):
    """Determine the type of object from its first line."""
    first_line = first_line.upper()
    if ' PROCEDURE ' in first_line:
        return 'procedures'
    elif ' PIPE ' in first_line:
        return 'pipes'
    elif ' STREAM ' in first_line:
        if ' SECURE ' in first_line:
            return 'secure_streams'
        else:
            return 'streams'
    elif ' VIEW ' in first_line:
        if ' MATERIALIZED ' in first_line:
            return 'materialized_views'
        elif ' SECURE ' in first_line:
            return 'secure_views'
        else:
            return 'views'
    elif ' TABLE ' in first_line:
        if ' EXTERNAL ' in first_line:
            return 'external_tables'
        elif ' SECURE ' in first_line:
            return 'secure_tables'
        else:
            return 'tables'
    elif ' FUNCTION ' in first_line:
        if ' SECURE ' in first_line:
            return 'secure_functions'
        else:
            return 'functions'
    elif ' TRIGGER ' in first_line:
        return 'triggers'
    elif 'INDEX' in first_line:
        return 'indexes'
    elif 'TYPE' in first_line:
        if 'SECURE' in first_line:
            return 'secure_types'
        else:
            return 'types'
    elif 'SEQUENCE' in first_line:
        if 'SECURE' in first_line:
            return 'secure_sequences'
        else:
            return 'sequences'
    elif 'SYNONYM' in first_line:
        return 'synonyms'
    elif 'ASSEMBLY' in first_line:
        return 'assemblies'
    elif 'TASK' in first_line:
        return 'tasks'
    elif 'WAREHOUSE' in first_line:
        if 'SECURE' in first_line:
            return 'secure_warehouses'
        else:
            return 'warehouses'
    elif 'STAGE' in first_line:
        if 'SECURE' in first_line:
            return 'secure_stages'
        else:
            return 'stages'
    elif 'PIPE' in first_line:
        if 'SECURE' in first_line:
            return 'secure_pipes'
        else:
            return 'pipes'
    
    elif 'INTEGRATION' in first_line:
        if 'API' in first_line:
            if 'SECURE' in first_line:
                return 'secure_api_integrations'
            else:
                return 'api_integrations'
        elif 'NOTIFICATION' in first_line:
            if 'SECURE' in first_line:
                return 'secure_notification_integrations'
            else:
                return 'notification_integrations'
        elif 'SECURITY' in first_line:
            if 'SECURE' in first_line:
                return 'secure_security_integrations'
            else:
                return 'security_integrations'
        elif 'SECURE' in first_line:
            return 'secure_integrations'
        else:
            return 'integrations'
    elif 'USER' in first_line:
        if 'SECURE' in first_line:
            return 'secure_users'
        else:
            return 'users'
    elif 'ROLE' in first_line:
        if 'SECURE' in first_line:
            return 'secure_roles'
        else:
            return 'roles'
    elif 'GRANT' in first_line:
        return 'grants'
    elif 'FILE FORMAT' in first_line:
        if 'SECURE' in first_line:
            return 'secure_file_formats'
        else:
            return 'file_formats'
    elif ' SCHEMA ' in first_line:
        return 'schemas'
    elif ' DATABASE ' in first_line:
        return 'databases'
    return None

def get_object_name(object_definition):
    """Extract the name of the object from its definition."""
    # Get the first line of the object definition
    first_line = object_definition.split('\n')[0].strip()
    
    # Look for the object name after CREATE/ALTER statements
    patterns = [
        # For procedures with parameters
        r'CREATE(?:\s+OR\s+REPLACE)?\s+PROCEDURE\s+"([^"]+)"\s*\(',
        # For procedures without parameters
        r'CREATE(?:\s+OR\s+REPLACE)?\s+PROCEDURE\s+"([^"]+)"\s*(?:RETURNS|LANGUAGE)',
        # For views (both quoted and unquoted names, including secure views)
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?(?:MATERIALIZED\s+)?VIEW\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For tables (both quoted and unquoted names, including transient/volatile)
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?(?:EXTERNAL\s+)?(?:TRANSIENT\s+)?(?:VOLATILE\s+)?TABLE\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For tables with IF NOT EXISTS
        r'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+([A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)?)',
        # For schemas (including shared schemas and those with comments)
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SHARED\s+)?SCHEMA\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For tasks
        r'CREATE(?:\s+OR\s+REPLACE)?\s+TASK\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For warehouses
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?WAREHOUSE\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For stages
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?STAGE\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For pipes
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?PIPE\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For streams
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?STREAM\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For integrations
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?(?:API\s+)?(?:NOTIFICATION\s+)?(?:SECURITY\s+)?INTEGRATION\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For users
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?USER\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For roles
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?ROLE\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For file formats
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?FILE\s+FORMAT\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For other objects (functions, triggers, indexes, etc.)
        r'CREATE(?:\s+OR\s+REPLACE)?\s+(?:SECURE\s+)?(?:FUNCTION|TRIGGER|INDEX|TYPE|SEQUENCE|SYNONYM|ASSEMBLY)\s+(?:"([^"]+)"|([A-Za-z0-9_]+))',
        # For ALTER statements
        r'ALTER\s+TABLE\s+(?:"([^"]+)"|([A-Za-z0-9_]+))\s+ADD\s+(?:CONSTRAINT|FOREIGN\s+KEY)',
        # For databases
        r'CREATE(?:\s+OR\s+REPLACE)?\s+DATABASE\s+(?:"([^"]+)"|([A-Za-z0-9_]+))'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, first_line, re.IGNORECASE)
        if match:
            # Return the first non-None group (either quoted or unquoted name)
            return next(g for g in match.groups() if g is not None)
    return None


def _sanitize_filename_basename(basename: str) -> str:
    """Replace characters invalid in filenames (Windows) with underscore."""
    invalid = r'\/:*?"<>|'
    for ch in invalid:
        basename = basename.replace(ch, '_')
    return basename


def extract_argument_signature(object_content: str) -> str | None:
    """
    Extract the argument list (signature) from a procedure or function DDL.
    Returns the normalized inner text between the first ( and its matching ),
    or None if not a procedure/function or matching paren not found.
    """
    content = object_content.strip()
    if not re.match(
        r'CREATE\s+(?:OR\s+REPLACE\s+)?(?:SECURE\s+)?(?:PROCEDURE|FUNCTION)\s+',
        content,
        re.IGNORECASE,
    ):
        return None
    # Find the first '(' that starts the argument list (after the object name).
    # Pattern: PROCEDURE|FUNCTION, then optional SECURE, then name (quoted or not), then optional ws, then (
    match = re.search(
        r'(?:PROCEDURE|FUNCTION)\s+(?:"[^"]*"|[A-Za-z0-9_]+)\s*(\()',
        content,
        re.IGNORECASE,
    )
    if not match:
        return None
    open_pos = match.start(1)
    depth = 1
    i = open_pos + 1
    while i < len(content) and depth > 0:
        if content[i] == '(':
            depth += 1
        elif content[i] == ')':
            depth -= 1
        i += 1
    if depth != 0:
        return None
    close_pos = i - 1
    inner = content[open_pos + 1 : close_pos]
    # Normalize: collapse whitespace, strip
    normalized = ' '.join(inner.split()).strip()
    # Replace filename-unsafe characters
    normalized = _sanitize_filename_basename(normalized)
    return normalized


def get_file_basename_for_object(object_content: str, object_type: str | None) -> str | None:
    """
    Return the file basename (no .sql) for this object. For procedures and functions,
    includes the argument signature so overloads get distinct files.
    """
    name = get_object_name(object_content)
    if name is None:
        return None
    if object_type in ('procedures', 'secure_procedures', 'functions', 'secure_functions'):
        sig = extract_argument_signature(object_content)
        if sig is not None:
            basename = f"{name}({sig})"
        else:
            basename = f"{name}()"
        return _sanitize_filename_basename(basename)
    return _sanitize_filename_basename(name)


def parse_sql_by_database_and_schema(sql_content, database_name_override=None, output_dir_override=None, include_schemas=None, exclude_schemas=None):
    """Parse SQL content and organize objects by database and schema.
    
    Args:
        sql_content: The SQL DDL content to parse
        database_name_override: Optional database name override
        output_dir_override: Optional output directory override
        include_schemas: List of schema names to include (takes precedence over exclude_schemas)
        exclude_schemas: List of schema names to exclude from parsing
    """
    if include_schemas is None:
        include_schemas = []
    if exclude_schemas is None:
        exclude_schemas = []
    
    # Normalize to uppercase for case-insensitive comparison
    include_schemas_upper = [s.upper() for s in include_schemas]
    exclude_schemas_upper = [s.upper() for s in exclude_schemas]
    
    # Determine filter mode: include takes precedence over exclude
    use_include_mode = len(include_schemas_upper) > 0
    # Extract multi-line comments and replace with placeholders
    sql_content, comments_dict = extract_multiline_comments(sql_content)

    # Extract database name from the SQL content
    if database_name_override:
        database_name = database_name_override
        print(f"Using specified database name: {database_name}")
    else:
        database_name = get_database_name(sql_content)
        print(f"Auto-detected database name: {database_name}")
 
    # Create base directory for all databases
    base_dir = Path(output_dir_override) if output_dir_override else Path('databases')
    base_dir.mkdir(exist_ok=True)
 
    # Find all schema statements and their line numbers
    schema_positions = []
    lines = sql_content.split('\n')

    for i, line in enumerate(lines):
        if re.search(r'create\s+or\s+replace\s+schema', line, re.IGNORECASE):
            schema_name = get_schema_name(line)
            if schema_name:
                schema_positions.append((i, schema_name))
    
    if not schema_positions:
        print("Warning: No schema statements found. Objects will be placed in a default schema.")
        schema_positions = [(0, 'default_schema')]
    
    print(f"Found {len(schema_positions)} schema(s)")
    
    # Process each schema section
    schema_objects = {}
    expected_paths = set()
    for i, (line_num, schema_name) in enumerate(schema_positions):
        # Filter schemas based on include/exclude mode
        schema_upper = schema_name.upper()
        if use_include_mode:
            if schema_upper not in include_schemas_upper:
                print(f"\nSkipping schema (not in include list): {schema_name}")
                continue
        else:
            if schema_upper in exclude_schemas_upper:
                print(f"\nSkipping excluded schema: {schema_name}")
                continue
        
        print(f"\nProcessing schema: {schema_name}")
        
        # Determine the end of this schema section
        if i < len(schema_positions) - 1:
            next_schema_start = schema_positions[i + 1][0]
        else:
            next_schema_start = len(lines)
        
        # Find all CREATE statements in this schema section
        schema_content = '\n'.join(lines[line_num:next_schema_start])
        
        # Find all CREATE statements
        # Note: (?:transient|volatile)\s+ is optional to match modifiers before TABLE
        create_pattern = r'create\s+(?:or\s+replace\s+)?(?:(?:transient|volatile)\s+)?(?:table|view|procedure|function|sequence|type|warehouse|database|schema|stage|file\s+format|pipe|stream|task|user|role|grant|integration|external\s+table|materialized\s+view|secure\s+view|secure\s+function|secure\s+procedure|secure\s+table|secure\s+sequence|secure\s+type|secure\s+warehouse|secure\s+stage|secure\s+file\s+format|secure\s+pipe|secure\s+stream|secure\s+task|secure\s+user|secure\s+role|secure\s+grant|secure\s+integration|secure\s+api\s+integration|secure\s+notification\s+integration|secure\s+security\s+integration|secure\s+external\s+table|secure\s+materialized\s+view|shared\s+schema|api\s+integration|notification\s+integration|security\s+integration)'
        
        create_matches = list(re.finditer(create_pattern, schema_content, re.IGNORECASE))
        
        print(f"  Found {len(create_matches)} CREATE statements")
        
        for j, match in enumerate(create_matches):
            start_pos = match.start()
            
            # Find the end of this object
            if j < len(create_matches) - 1:
                end_pos = create_matches[j + 1].start()
            else:
                end_pos = len(schema_content)
            
            # Extract the object content
            object_content = schema_content[start_pos:end_pos].strip()
            
            # Determine object type and file basename (name + signature for procedures/functions)
            first_line = object_content.split('\n')[0]
            object_type = get_object_type(first_line)
            file_basename = get_file_basename_for_object(object_content, object_type)
            
            if file_basename and object_type:
                # Create directory structure
                database_dir = base_dir / database_name
                schema_dir = database_dir / schema_name
                type_dir = schema_dir / object_type
                type_dir.mkdir(parents=True, exist_ok=True)
                
                # Restore comments before writing
                object_content_with_comments = restore_comments(object_content, comments_dict)
                
                # Write object to file
                file_path = type_dir / f"{file_basename}.sql"
                try:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(object_content_with_comments)
                    print(f"    ✓ Saved: {object_type}/{file_basename}.sql")
                    expected_paths.add(file_path.resolve())
                except Exception as e:
                    print(f"    ✗ Error saving {file_basename}: {str(e)}")
                    continue
                
                # Track object count
                if schema_name not in schema_objects:
                    schema_objects[schema_name] = {}
                if object_type not in schema_objects[schema_name]:
                    schema_objects[schema_name][object_type] = 0
                schema_objects[schema_name][object_type] += 1
            else:
                print(f"    ⚠ Warning: Could not determine type/name for object starting with: {first_line[:50]}...")
    # After all objects are written
    database_dir = (base_dir / database_name)
    do_prune = True  # or pass via CLI
    dry_run = False  # or pass via CLI

    if do_prune:
        print("\nPruning files not present in the current dump...")
        summary = prune_removed_files(database_dir, expected_paths, dry_run=dry_run)
        if dry_run:
            print("Prune summary (dry-run): would remove "
                f"{summary.get('removed_files',0)} files and "
                f"{summary.get('removed_dirs',0)} empty dirs")
        else:
            print("Prune summary: removed "
                f"{summary.get('removed_files',0)} files and "
                f"{summary.get('removed_dirs',0)} empty dirs")
            
    
    # Print summary
    print("\n" + "="*60)
    print("DATABASE AND SCHEMA ORGANIZATION SUMMARY")
    print("="*60)
    print(f"Database: {database_name}")
    print(f"Output Directory: {base_dir}")
    
    total_objects = 0
    for schema_name, types in schema_objects.items():
        schema_total = sum(types.values())
        total_objects += schema_total
        print(f"\n{schema_name}: {schema_total} objects")
        for obj_type, count in types.items():
            print(f"  {obj_type}: {count}")
    
    print(f"\nTotal objects organized: {total_objects}")
    print(f"Total schemas: {len(schema_objects)}")
    return schema_objects

def _standalone_main():
    """Standalone main function for running ddl_parser.py directly."""
    parser = argparse.ArgumentParser(description='Parse SQL and organize objects by database and schema')
    parser.add_argument('--sql-file', default='full_db/fulldb.sql', help='SQL file to parse (default: fulldb.sql)')
    parser.add_argument('--database-name', help='Override database name (default: auto-detect)')
    parser.add_argument('--output-dir', default='databases', help='Output directory (default: databases)')
    
    args = parser.parse_args()

    print(os.getcwd())
    
    print("SQL Database Parser - Organizing objects by database and schema")
    print("="*60)
    
    # Read the SQL file
    sql_file = args.sql_file
    try:
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        print(f"Successfully read {sql_file} (size: {len(sql_content)} bytes)")
    except FileNotFoundError:
        print(f"Error: {sql_file} not found")
        return
    except Exception as e:
        print(f"Error reading {sql_file}: {e}")
        return
    
    # Parse and organize by database and schema
    parse_sql_by_database_and_schema(sql_content, args.database_name, args.output_dir)
    
    print("\n" + "="*60)
    print("PROCESSING COMPLETE")
    print("="*60)
    print("Objects have been organized into database and schema directories.")
    print(f"Check the '{args.output_dir}' folder for the organized structure.")

if __name__ == "__main__":
    _standalone_main()
