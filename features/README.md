# YAML Reference Features Specification

This directory contains Gherkin feature files that define the expected behavior of the `yaml-reference-cli` tool. The tool processes YAML files with special tags (`!reference`, `!reference-all`, `!merge`, `!flatten`, `!ignore`) and outputs resolved JSON documents.

## Overview

The `yaml-reference-cli` is a command-line tool that:

1. Takes a YAML file as input
2. Resolves all `!reference`, `!reference-all`, `!merge`, `!flatten`, and `!ignore` tags
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

# Flow style with anchor
key: !reference {path: other-file.yaml, anchor: my_anchor}

# Block style
key: !reference
  path: other-file.yaml

# Block style with anchor
key: !reference
  path: other-file.yaml
  anchor: my_anchor
```

### Behavior:

- Replaces the tag with the content of the referenced file
- When `anchor` is specified, extracts only the value associated with that anchor from the referenced file instead of the whole document
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
- Returns error code `1` if `anchor` is specified but does not exist in the referenced file

## 3. `!reference-all` Tag Behavior

The `!reference-all` tag collects content from multiple files matching a glob pattern into an array. See the specs in the [reference-all](./reference-all/) directory.

### Syntax:

```yaml
# Flow style
items: !reference-all {glob: data/*.yaml}

# Flow style with anchor
items: !reference-all {glob: data/*.yaml, anchor: my_anchor}

# Block style
items: !reference-all
  glob: data/*.yaml

# Block style with anchor
items: !reference-all
  glob: data/*.yaml
  anchor: my_anchor
```

### Behavior:

- Collects all files matching the glob pattern
- Returns an array containing the content of each matched file
- When `anchor` is specified, extracts only the value associated with that anchor from each matched file instead of the whole document
- If only one file matches, returns a single-element array
- Files are processed in alphabetical order by their full relative path
- Supports the same path restrictions as `!reference`

### Examples:

- `!reference-all {glob: configs/*.yaml}` - collects all YAML files in `configs/` directory
- `!reference-all {glob: data-*.yaml}` - collects all files matching pattern
- `!reference-all {glob: topics/*/summary.yaml}` - collects all summary files in subdirectories of the `topics/` directory
- `!reference-all {glob: services/*.yaml, anchor: config}` - collects the `config` anchor value from each matched file

### Path Restrictions:

- Same as `!reference`: cannot reference files outside root directory
- Glob patterns are evaluated relative to the file containing the tag
- Symlinks pointing outside root directory are rejected

### Glob Matching Behavior:

- If the glob pattern uses an absolute path (e.g., `/home/user/*`), an error is raised (return code `1`).
- If the glob pattern matches a disallowed file (e.g., outside the root directory via relative traversal or symlinks escaping the root), that file is silently omitted from the resulting array; no error is raised.
- If the glob pattern matches no files at all (either because no files exist or all matched files are disallowed), the result is an empty array; no error is raised.

### Error Conditions:

- Returns error code `1` if the glob pattern itself uses an absolute path
- Returns error code `1` if the glob pattern matches the input file itself (self-referential/cyclical reference)
- Returns error code `1` if a circular reference is detected (a matched file references back to the input file)
- Returns error code `1` if `anchor` is specified but does not exist in any matched file

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

## 6. `!ignore` Tag Behavior

The `!ignore` tag suppresses a node from the output while preserving any anchors defined within it, enabling patterns like shared definition blocks that should not appear in the final document. See the specs in the [ignore](./ignore/) directory.

### Syntax:

```yaml
# Ignore a map key's value (omits the key entirely)
hidden_key: !ignore some_value

# Ignore a list item
items:
  - normal_item
  - !ignore hidden_item

# Ignore a nested structure (entire subtree is pruned)
definitions: !ignore
  a: 1
  b: 2

# Ignore the root of a document
!ignore
root_key: value
```

### Behavior:

- **Map keys**: A map key whose value is tagged `!ignore` is omitted entirely from the output object.
- **List items**: A list item tagged `!ignore` is removed from the output array.
- **Nested structures**: When a node is tagged `!ignore`, the entire subtree is pruned; its children are not evaluated for output.
- **Nested ignores**: An `!ignore` nested inside another `!ignore` is supported without errors.
- **Root `!ignore`**: If the document root is tagged `!ignore`, the output is `null` (equivalent to an empty document).
- **All-ignored sequences**: A sequence where all items are `!ignore` results in `[]`.
- **All-ignored maps**: A map where all values are `!ignore` results in `{}`.

### Anchor & Alias Behavior:

- **Anchors inside `!ignore` nodes**: Anchors defined within an `!ignore` node remain active and can be referenced elsewhere in the document via aliases or `!reference {anchor: ...}`. The node is removed from output, but its anchors are still registered.
- **Aliases to `!ignore` anchors**: An alias (`*anchor`) that points to a node tagged `!ignore` is treated as if the `!ignore` were inlined at that position — the alias is omitted from the output just as the original tagged node would be.

### Interaction with Other Tags:

- **`!reference` to an `!ignore` file**: If the referenced file's root is `!ignore`, the referencing key is omitted entirely from the parent output object (not preserved with a null or empty value). For example, `data: !reference {path: ignored.yaml}` produces `{}` — the `data` key itself is absent.
- **`!reference-all` with ignored files**: Files whose root is `!ignore` are silently omitted from the result array; they do not contribute a `null` entry.
- **Direct `!reference {anchor: ...}` to an anchor inside an `!ignore` node**: Permitted. The anchor value is extracted and used normally, even though the containing node is suppressed from output.

### Examples:

```yaml
# definitions.yaml — anchors are defined but the file root is !ignore
!ignore
defaults: &defaults
  host: localhost
  port: 3000

# input.yaml
server: !reference {path: definitions.yaml, anchor: defaults}
# output: {"server": {"host": "localhost", "port": 3000}}
```

```yaml
# Hiding implementation details with anchors
anchors: !ignore
  - &payload
    user: alice
    role: admin

request:
  body: *payload
# output: {"request": {"body": {"role": "admin", "user": "alice"}}}
```

## 7. Protection Against Cyclical References

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

## 8. Basic Reference Access Restriction with "allowed" Paths

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
