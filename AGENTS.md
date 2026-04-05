# AGENTS.md - yaml-reference-specs

## Project Purpose

This is a **Gherkin specification suite** for testing `yaml-reference-cli` implementations (Python, TypeScript, etc.). The project **does not contain the CLI itself**—it's a test harness that validates conformance across different language implementations.

**For detailed architecture and development guidance, see [`.github/copilot-instructions.md`](.github/copilot-instructions.md).**

## Running Tests

```bash
# Required: set the CLI under test
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yaml-reference-cli

# Run full test suite
go run .

# Using make (with dummy CLI for quick validation)
make test-echo

# Install and run as binary
go install github.com/dsillman2000/yaml-reference-specs@latest
yaml-reference-specs

# Output format options
go run . -format pretty   # Default: colored terminal output
go run . -format junit    # JUnit XML for CI/CD
go run . -format json     # JSON output
```

## Key Requirements

| Requirement | Details |
|-------------|---------|
| **CLI Executable** | `YAML_REFERENCE_CLI_EXECUTABLE` env var (required; test panics if missing) |
| **JSON Output** | Keys sorted alphabetically at all nesting levels |
| **Exit Codes** | `0` on success, `1` on any error |
| **Test Isolation** | Each scenario runs in isolated temp directory (auto-cleaned after test) |

## YAML Tags Tested

| Tag | Behavior |
|-----|----------|
| `!reference` | Import file content; supports `path` + optional `anchor` |
| `!reference-all` | Import files matching glob pattern into array |
| `!merge` | Shallow merge objects, last-write-wins semantics (not YAML 1.1 first-write-wins) |
| `!flatten` | Recursively flatten nested arrays to single level |
| `!ignore` | Suppress node from output, preserve internal anchors |

## Path Restrictions (Security Model)

All file references are restricted relative to the input file's root directory:

- ✅ **Allowed:** References within same directory or subdirectories (`subdir/file.yaml`)
- ❌ **Blocked:** Upward traversal outside root (`../../../etc/passwd`)
- ❌ **Blocked:** Absolute paths (`/etc/passwd`) — unless explicitly allowed via `--allow` flag
- ❌ **Blocked:** Symlinks that escape outside root directory

**Glob patterns:** Files matching disallowed paths are silently omitted (no error thrown).

## Test Structure

- **`features/*.feature`** — Gherkin scenarios (embedded in binary via `//go:embed`)
- **`main.go`** — Step definitions, scenario initialization, and test context management
- **`features/README.md`** — Comprehensive specification documentation

## Important Notes

- Feature files are **embedded in the binary** — no external file reads during tests
- **Multi-document YAML:** `!reference` cannot target multi-doc files (error); use `!reference-all` instead
- **Anchor scope:** Anchors and aliases resolve only within the file they're defined in (not cross-file)
- **Glob patterns:** Files matching disallowed paths are silently omitted (not an error condition)