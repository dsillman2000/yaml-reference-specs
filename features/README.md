# YAML Reference Features Specification

This directory contains Gherkin feature files that define the expected behavior of the `yaml-reference-cli` tool. The tool processes YAML files with special tags (`!reference`, `!reference-all`, `!merge`, `!flatten`) and outputs resolved JSON documents.

## Overview

The `yaml-reference-cli` is a command-line tool that:

1. Takes a YAML file as input
2. Resolves all `!reference`, `!reference-all`, `!merge`, and `!flatten` tags
3. Outputs the fully resolved JSON document to stdout

## 1. CLI Behavior

See the specs in [cli-api.feature](./cli-api.feature).

### Basic Usage

```bash
yaml-reference-cli <input-yaml-file>
```

The CLI reads a YAML file from disk, processes all special tags, and prints the resolved JSON document to stdout. The output is always valid JSON with keys sorted alphabetically.

### Key Characteristics:

- **Input**: Path to a YAML file on disk
- **Output**: Resolved JSON document printed to stdout
- **Return Codes**:
  - `0` for successful compilation
  - `1` for errors (file not found, cyclical references, access violations, etc.)
- **JSON Output**: Keys are sorted alphabetically at all nesting levels
- **YAML Features**: Supports standard YAML features including anchors (`&anchor`) and aliases (`*anchor`)

### Examples:

- Files without special tags are simply converted to JSON
- Anchors and aliases are resolved before special tag processing
- Output maintains consistent key ordering

## 2. `!reference` Tag Behavior

The `!reference` tag allows embedding content from other YAML files into the current document. See the specs in the [reference](./reference/) directory.

### Syntax:

```yaml
# Flow style
key: !reference {path: other-file.yaml}

# Block style
key: !reference
  path: other-file.yaml
```

### Behavior:

- Replaces the tag with the content of the referenced file
- Works with both scalar values and structured data
- References can be nested (files can reference other files)
- Supports both relative and absolute paths within the allowed scope

### Path Restrictions:

- **Cannot reference files outside the root directory** of the input file
- Absolute paths (e.g., `/etc/passwd`) are rejected
- Paths attempting to navigate above the root directory (e.g., `../secret.yaml`) are rejected
- Symlinks that point outside the root directory are also rejected

### Error Conditions:

- Returns error code `1` if referenced file doesn't exist
- Returns error code `1` if a circular reference is detected
- Returns error code `1` if path violates access restrictions

## 3. `!reference-all` Tag Behavior

The `!reference-all` tag collects content from multiple files matching a glob pattern into an array. See the specs in the [reference-all](./reference-all/) directory.

### Syntax:

```yaml
# Flow style
items: !reference-all {glob: data/*.yaml}

# Block style
items: !reference-all
  glob: data/*.yaml
```

### Behavior:

- Collects all files matching the glob pattern
- Returns an array containing the content of each matched file
- If only one file matches, returns a single-element array
- Files are processed in alphabetical order
- Supports the same path restrictions as `!reference`

### Examples:

- `!reference-all {glob: configs/*.yaml}` - collects all YAML files in `configs/` directory
- `!reference-all {glob: data-*.yaml}` - collects all files matching pattern
- `!reference-all {glob: topics/*/summary.yaml}` - collects all summary files in subdirectories of the `topics/` directory

### Path Restrictions:

- Same as `!reference`: cannot reference files outside root directory
- Glob patterns are evaluated relative to the file containing the tag
- Symlinks pointing outside root directory are rejected

## 4. `!flatten` Tag Behavior

The `!flatten` tag recursively flattens nested sequences (arrays/lists) into a single-level sequence. See the specs in the [flatten](./flatten/) directory.

### Syntax:

```yaml
# Flow style
items: !flatten [[1, 2], [3, 4]]

# Block style
items: !flatten
  - [1, 2]
  - [3, 4]
```

### Behavior:

- Recursively flattens all nested sequences
- Preserves the order of elements
- Works with sequences of variable nesting depths
- If input is already flat, returns unchanged
- Only affects sequences; other data types remain unchanged

### Examples:

- `!flatten [[1, 2], [3, 4]]` → `[1, 2, 3, 4]`
- `!flatten [[[[1, 2]]]]` → `[1, 2]`
- `!flatten [[[[1, 2]], [3, [4]]], [[5, 6]], [7]]` → `[1, 2, 3, 4, 5, 6, 7]`

## 5. `!merge` Tag Behavior

The `!merge` tag accepts a sequence of objects and merges them into a single object using **last-write-wins** semantics. The `!merge` tag flattens its sequence input to work with `!reference` and `!reference-all`. See the specs in the [merge](./merge/) directory.

### Syntax:

```yaml
# Flow style
result: !merge [{a: 1, b: 2}, {b: 3, c: 4}]

# Block style
result: !merge
  - { a: 1, b: 2 }
  - { b: 3, c: 4 }
```

### Behavior:

- **Last-write-wins semantics**: `!merge` uses last-write-wins semantics, similar to EcmaScript's `{...a, ...b, ...c}` spread operator. The last instance of a key always takes precedence over any previous instance of a key. This is notably different than the YAML 1.1 `<<:` merge key, which uses first-write-wins semantics. This was done intentionally to provide a more intuitive "defaults then overrides" authoring pattern.
- **Shallow merge only**: There is no "deep merging" of objects. Only keys at the top level are compared.
- **Internal recursive flattening**: Sequences within the merge input are recursively flattened before merging. This allows `!reference-all` (which resolves to an array of objects) to be used directly inside !merge without needing a separate !flatten wrapper.
- **`Null` values override**: `{key: null}` in a later object replaces an earlier `{key: "value"}`.
- **Error handling**: After internal flattening, every leaf item must be an object. Scalars or sequences-of-scalars cause a non-zero exit code.
- **Trivial cases**: Flattening an empty sequence yields and empty object

### Error Conditions:

- Returns error code `1` if any item, after internal recursive flattening, is not an object (e.g. scalars or sequences of scalars)

### Examples:

```yaml
# defaults.yaml
host: localhost
port: 3000
debug: true

# input.yaml
server: !merge
  - !reference { path: defaults.yaml }
  - host: prod.example.com
    debug: null
    tls: true
  - host: cdn.example.com

# output:
# {
#   "server": {
#     "host": "cdn.example.com",
#     "port": 3000,
#     "debug": null,
#     "tls": true
#   }
# }
```

## 6. Protection Against Cyclical References

The system includes robust protection against cyclical references to prevent infinite loops.

### Detection Mechanisms:

1. **Direct self-reference**: File referencing itself
2. **Indirect cycles**: A references B, B references C, C references A
3. **Nested cycles**: Any circular dependency in the reference graph

### Behavior:

- Returns error code `1` when any cycle is detected
- Cycle detection occurs during compilation
- Prevents infinite recursion during reference resolution
- Error messages should indicate the cycle was detected

## 7. Basic Reference Access Restriction with "allowed" Paths

While the default behavior restricts references to within the root directory, the system supports explicit path allowances for controlled external access.

### Default Behavior (Restrictive):

- All references must stay within the root directory containing the input file
- No upward traversal (`../`) allowed outside of the root directory containing the input file.
- No absolute paths allowed
- Symlinks are followed but must not escape root directory

### Explicit Allowance Mechanism:

- Certain paths can be explicitly "allowed" during compilation using the `--allow` CLI flag
- When a path is allowed, references to that path (and its subdirectories) are permitted
- Allows controlled access to specific external directories
- Multiple `--allow` flags can be used to permit multiple paths

### CLI Usage with Allowed Paths:

```bash
# Allow a specific absolute path (still needs to be referenced relatively)
yaml-reference-cli --allow /absolute/path/to/project input.yaml

# Allow two specific relative paths
yaml-reference-cli --allow ../../../my-other-project --allow ../../../resources input.yaml
```

### Example:

```yaml
# Input file in "application/" directory
project: !reference { path: ../project/info.yaml }
```

With explicit allowance using `--allow ../project`, this reference would be permitted. Without allowance, it would be rejected.

### Security Implications:

- Default deny policy enhances security
- Explicit allowances provide flexibility when needed
- Prevents accidental or malicious access to sensitive files
- Maintains clear boundaries between projects
- Allowed paths are resolved as absolute paths for consistent evaluation
