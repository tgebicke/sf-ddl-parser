import os
import re
import argparse
import hashlib
from pathlib import Path


def _normalize_blank_lines(content: str) -> str:
    content = content.replace('\r\n', '\n')
    lines = content.split('\n')

    # Find the line marking the start of the body (after AS or AS $$)
    as_index = None
    for i, line in enumerate(lines):
        stripped = line.strip()
        if re.match(r'^AS(\s+\$\$|\s*$)', stripped, re.IGNORECASE):
            as_index = i
            break

    # Use lines after AS for ratio; fall back to all lines if AS not found
    check_lines = lines[as_index + 1:] if as_index is not None else lines

    blank = sum(1 for l in check_lines if not l.strip())
    non_blank = len(check_lines) - blank

    if non_blank > 0 and blank >= non_blank:
        content = re.sub(r'\n{2,}', '\n', content)
    return content


def restore_sp_formatting(object_content: str) -> str:
    """
    Restore a stored procedure body from Snowflake's single-quote encoding
    to $$-delimited format.

    Transforms:
        AS 'BEGIN\\n    SELECT ''hello'';\\nEND';
    Into:
        AS $$\\nBEGIN\\n    SELECT 'hello';\\nEND\\n$$;

    Returns the content unchanged if it already uses $$ delimiters or the
    expected AS '...' pattern is not found.
    """
    match = re.search(r"(AS\s*)'", object_content, re.IGNORECASE)
    if not match:
        return object_content  # Already in $$ format or unrecognized — skip

    open_quote_pos = match.end() - 1  # position of the opening '

    close_match = re.search(r"'(;?\s*)$", object_content, re.DOTALL)
    if not close_match or close_match.start() <= open_quote_pos:
        return object_content  # Can't locate closing quote safely — skip

    close_quote_pos = close_match.start()  # position of the closing '

    body = object_content[open_quote_pos + 1 : close_quote_pos]
    body = body.replace("''", "'")

    before = object_content[:open_quote_pos]
    after = object_content[close_quote_pos + 1:]  # after closing ' (preserves ;)

    return before + "$$\n" + body + "\n$$" + after


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


def extract_comments(sql_content: str) -> tuple[str, dict[str, str]]:
    """
    Extract both /* */ multi-line and -- single-line comments, replacing each with a placeholder.
    This must be run before any single-quote scanning so that quotes inside comments
    (e.g. in procedure headers like  EXECUTE AS CALLER -- it's the owner) don't mislead the parser.
    Returns (modified_content, comments_dict).
    """
    comments = {}
    pattern = re.compile(r'/\*[\s\S]*?\*/|--[^\n]*')
    matches = list(pattern.finditer(sql_content))
    result = sql_content
    for match in reversed(matches):
        text = match.group(0)
        h = hashlib.md5(text.encode('utf-8')).hexdigest()[:8]
        comments[h] = text
        result = result[:match.start()] + f"<comment={h}/>" + result[match.end():]
    return result, comments


def _in_no_go_zone(pos: int, no_go_zones: list[dict]) -> bool:
    """Return True if pos falls within any no-go zone (inclusive of zone start)."""
    return any(z['start'] <= pos < z['end'] for z in no_go_zones)


def find_proc_boundaries(sql_content: str) -> list[dict]:
    """
    Pass 1: Scan the entire file for CREATE PROCEDURE / CREATE FUNCTION and determine
    exact boundaries using the AS '...' string literal delimiter.
    Returns list of {start, end, type, content} with character offsets into sql_content.
    These become no-go zones for all subsequent passes.
    """
    boundaries = []
    proc_re = re.compile(
        r'CREATE\s+(?:OR\s+REPLACE\s+)?(?:SECURE\s+)?(?:PROCEDURE|FUNCTION)\s+',
        re.IGNORECASE
    )
    # Match AS directly followed by optional whitespace then '.
    # This avoids false matches on EXECUTE AS CALLER/OWNER (no quote after)
    # and COMMENT='...as per...' (the 'as' there is not directly before a quote).
    body_as_re = re.compile(r'\bAS\s*\'', re.IGNORECASE)
    n = len(sql_content)

    for match in proc_re.finditer(sql_content):
        obj_start = match.start()

        # Determine object type from the first line
        eol = sql_content.find('\n', obj_start)
        first_line = sql_content[obj_start: eol if eol != -1 else n]
        obj_type = get_object_type(first_line) or 'procedures'

        # Find the body-opening AS ' after the CREATE header
        body_as_match = body_as_re.search(sql_content, match.end())
        if not body_as_match:
            continue

        # The opening quote is the last character of the AS ' match
        quote_start = body_as_match.end() - 1

        # Walk forward handling '' escape sequences to find the closing quote
        i = quote_start + 1
        while i < n:
            if sql_content[i] == "'":
                if i + 1 < n and sql_content[i + 1] == "'":
                    i += 2  # escaped quote ''
                else:
                    break   # closing quote
            else:
                i += 1

        if i >= n:
            continue  # unclosed string literal — skip

        # i is on the closing quote; consume optional trailing semicolon
        end_pos = i + 1
        j = end_pos
        while j < n and sql_content[j] in (' ', '\t', '\r'):
            j += 1
        if j < n and sql_content[j] == ';':
            end_pos = j + 1

        boundaries.append({
            'start': obj_start,
            'end': end_pos,
            'type': obj_type,
            'content': sql_content[obj_start:end_pos],
        })

    return boundaries


def find_schema_boundaries(sql_content: str, no_go_zones: list[dict]) -> list[dict]:
    """
    Pass 2: Find all top-level CREATE SCHEMA positions, filtered against no-go zones.
    Each schema's section runs from its start to the start of the next schema (or EOF).
    Returns list of {start, end, schema_name}.
    """
    schema_re = re.compile(r'create\s+or\s+replace\s+(?:shared\s+)?schema\s+', re.IGNORECASE)
    found = []
    for match in schema_re.finditer(sql_content):
        pos = match.start()
        if _in_no_go_zone(pos, no_go_zones):
            continue
        eol = sql_content.find('\n', pos)
        line = sql_content[pos: eol if eol != -1 else len(sql_content)]
        schema_name = get_schema_name(line)
        if schema_name:
            found.append({'start': pos, 'schema_name': schema_name})

    n = len(sql_content)
    boundaries = []
    for i, s in enumerate(found):
        end = found[i + 1]['start'] if i + 1 < len(found) else n
        boundaries.append({'start': s['start'], 'end': end, 'schema_name': s['schema_name']})
    return boundaries


def find_other_object_boundaries(sql_content: str, schema_boundaries: list[dict], no_go_zones: list[dict]) -> list[dict]:
    """
    Pass 3: Within each schema section, find all non-procedure/function CREATE statements,
    skipping any whose position falls inside a no-go zone.
    End boundary for each object = start of the next CREATE in the section (whether in a
    no-go zone or not), so that proc bodies are never absorbed into a preceding object.
    Returns list of {start, end, type, schema_name, content}.
    """
    create_re = re.compile(
        r'create\s+(?:or\s+replace\s+)?(?:(?:transient|volatile)\s+)?'
        r'(?:table|view|procedure|function|sequence|type|warehouse|database|schema|stage|'
        r'file\s+format|pipe|stream|task|user|role|grant|integration|external\s+table|'
        r'materialized\s+view|secure\s+view|secure\s+function|secure\s+procedure|'
        r'secure\s+table|secure\s+sequence|secure\s+type|secure\s+warehouse|secure\s+stage|'
        r'secure\s+file\s+format|secure\s+pipe|secure\s+stream|secure\s+task|secure\s+user|'
        r'secure\s+role|secure\s+grant|secure\s+integration|secure\s+api\s+integration|'
        r'secure\s+notification\s+integration|secure\s+security\s+integration|'
        r'secure\s+external\s+table|secure\s+materialized\s+view|shared\s+schema|'
        r'api\s+integration|notification\s+integration|security\s+integration)',
        re.IGNORECASE
    )

    boundaries = []

    for schema in schema_boundaries:
        s_start = schema['start']
        s_end = schema['end']
        schema_name = schema['schema_name']
        section = sql_content[s_start:s_end]

        matches = list(create_re.finditer(section))
        if not matches:
            continue

        # All CREATE starts (including those in no-go zones) serve as end boundaries
        # for preceding objects, so a non-proc object never absorbs a proc's content.
        boundary_positions = sorted({m.start() for m in matches} | {len(section)})

        for m in matches:
            abs_pos = s_start + m.start()

            # Skip anything inside a no-go zone
            if _in_no_go_zone(abs_pos, no_go_zones):
                continue

            # Determine type; skip procs/functions — those are handled in Pass 1
            eol = section.find('\n', m.start())
            first_line = section[m.start(): eol if eol != -1 else len(section)]
            obj_type = get_object_type(first_line)
            if obj_type in ('procedures', 'functions', 'secure_procedures', 'secure_functions'):
                continue

            end_rel = next((bp for bp in boundary_positions if bp > m.start()), len(section))
            content = section[m.start():end_rel].strip()

            boundaries.append({
                'start': abs_pos,
                'end': s_start + end_rel,
                'type': obj_type,
                'schema_name': schema_name,
                'content': content,
            })

    return boundaries


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
    elif 'FILE FORMAT' in first_line:
        if 'SECURE' in first_line:
            return 'secure_file_formats'
        else:
            return 'file_formats'
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


def _signature_to_types_only(signature_str: str) -> str:
    """
    Reduce a procedure/function argument signature to comma-separated type names only.
    Strips parameter names and precision/scale (e.g. NUMBER(38,0) -> NUMBER).
    """
    if not signature_str or not signature_str.strip():
        return ""
    # Split by comma only when not inside parentheses
    segments = []
    start = 0
    depth = 0
    for i, ch in enumerate(signature_str):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            segments.append(signature_str[start:i].strip())
            start = i + 1
    segments.append(signature_str[start:].strip())

    types = []
    # Strip optional leading IN/OUT/INOUT (procedure style)
    in_out_re = re.compile(r"^(?:IN|OUT|INOUT)\s+", re.IGNORECASE)
    # Strip trailing (p) or (p,s) from type
    precision_re = re.compile(r"\s*\(\s*\d+\s*(?:,\s*\d+)?\s*\)\s*$")

    for seg in segments:
        if not seg:
            continue
        seg = in_out_re.sub("", seg, count=1).strip()
        parts = seg.split(None, 1)  # first token = param name, rest = type
        if len(parts) < 2:
            type_spec = parts[0] if parts else ""
        else:
            type_spec = parts[1]
        type_spec = precision_re.sub("", type_spec).strip()
        if type_spec:
            types.append(type_spec.upper())
    return ",".join(types)


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
            types_only = _signature_to_types_only(sig)
            basename = f"{name}({types_only})" if types_only else f"{name}()"
        else:
            basename = f"{name}()"
        return _sanitize_filename_basename(basename)
    return _sanitize_filename_basename(name)


def parse_sql_by_database_and_schema(sql_content, database_name_override=None, output_dir_override=None, include_schemas=None, exclude_schemas=None, restore_sp_fmt=False):
    """Parse SQL content and organize objects by database and schema.

    Discovery happens in three passes before any files are written:
      Pass 1 — Find all procedure/function boundaries (no-go zones) using AS '...' scanning.
      Pass 2 — Find all schema boundaries, filtered against no-go zones.
      Pass 3 — Find all other object boundaries within each schema section, skipping no-go zones.
    """
    if include_schemas is None:
        include_schemas = []
    if exclude_schemas is None:
        exclude_schemas = []

    include_schemas_upper = [s.upper() for s in include_schemas]
    exclude_schemas_upper = [s.upper() for s in exclude_schemas]
    use_include_mode = len(include_schemas_upper) > 0

    # Step 0: Strip all comments (/* */ and --) so quotes inside them don't mislead the parser
    sql_content, comments_dict = extract_comments(sql_content)

    # Detect database name
    if database_name_override:
        database_name = database_name_override
        print(f"Using specified database name: {database_name}")
    else:
        database_name = get_database_name(sql_content)
        print(f"Auto-detected database name: {database_name}")

    base_dir = Path(output_dir_override) if output_dir_override else Path('databases')
    base_dir.mkdir(exist_ok=True)

    # Pass 1: Wall off procedures and functions
    no_go_zones = find_proc_boundaries(sql_content)
    print(f"Found {len(no_go_zones)} procedure/function(s)")

    # Pass 2: Find schema boundaries (filtered against no-go zones)
    schema_boundaries = find_schema_boundaries(sql_content, no_go_zones)
    if not schema_boundaries:
        print("Warning: No schema statements found. Objects will be placed in a default schema.")
        schema_boundaries = [{'start': 0, 'end': len(sql_content), 'schema_name': 'default_schema'}]
    print(f"Found {len(schema_boundaries)} schema(s)")

    # Apply schema include/exclude filter
    def _schema_included(name):
        upper = name.upper()
        if use_include_mode:
            return upper in include_schemas_upper
        return upper not in exclude_schemas_upper

    filtered_schemas = [s for s in schema_boundaries if _schema_included(s['schema_name'])]
    for s in schema_boundaries:
        if not _schema_included(s['schema_name']):
            print(f"  Skipping schema: {s['schema_name']}")

    # Pass 3: Find all other objects within the filtered schema sections
    other_boundaries = find_other_object_boundaries(sql_content, filtered_schemas, no_go_zones)

    # Assign each proc/function to its schema, then combine with other objects
    all_boundaries = []
    for proc in no_go_zones:
        schema_name = None
        for s in filtered_schemas:
            if s['start'] <= proc['start'] < s['end']:
                schema_name = s['schema_name']
                break
        if schema_name is None:
            continue  # proc not in any included schema
        all_boundaries.append({**proc, 'schema_name': schema_name})

    all_boundaries.extend(other_boundaries)
    all_boundaries.sort(key=lambda b: b['start'])

    # Write pass
    schema_objects = {}
    expected_paths = set()

    for boundary in all_boundaries:
        schema_name = boundary['schema_name']
        obj_type = boundary['type']
        content = boundary['content']

        if not obj_type:
            print(f"    ⚠ Warning: Could not determine type for: {content.split(chr(10))[0][:50]}...")
            continue

        # Restore comments, then optionally reformat SP body
        content_out = restore_comments(content, comments_dict)
        if restore_sp_fmt and obj_type in ('procedures', 'secure_procedures', 'functions', 'secure_functions'):
            content_out = restore_sp_formatting(content_out)

        file_basename = get_file_basename_for_object(content_out, obj_type)
        if not file_basename:
            print(f"    ⚠ Warning: Could not determine name for: {content_out.split(chr(10))[0][:50]}...")
            continue

        type_dir = base_dir / database_name / schema_name / obj_type
        type_dir.mkdir(parents=True, exist_ok=True)

        file_path = type_dir / f"{file_basename}.sql"
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(_normalize_blank_lines(content_out))
            print(f"    ✓ Saved: {schema_name}/{obj_type}/{file_basename}.sql")
            expected_paths.add(file_path.resolve())
        except Exception as e:
            print(f"    ✗ Error saving {file_basename}: {str(e)}")
            continue

        schema_objects.setdefault(schema_name, {})
        schema_objects[schema_name].setdefault(obj_type, 0)
        schema_objects[schema_name][obj_type] += 1

    # Prune files no longer in the dump
    database_dir = base_dir / database_name
    print("\nPruning files not present in the current dump...")
    summary = prune_removed_files(database_dir, expected_paths)
    print(f"Prune summary: removed {summary.get('removed_files', 0)} files and {summary.get('removed_dirs', 0)} empty dirs")

    # Summary
    print("\n" + "=" * 60)
    print("DATABASE AND SCHEMA ORGANIZATION SUMMARY")
    print("=" * 60)
    print(f"Database: {database_name}")
    print(f"Output Directory: {base_dir}")
    total_objects = 0
    for sn, types in schema_objects.items():
        schema_total = sum(types.values())
        total_objects += schema_total
        print(f"\n{sn}: {schema_total} objects")
        for ot, count in types.items():
            print(f"  {ot}: {count}")
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
