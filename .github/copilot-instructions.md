# Copilot Instructions for yaml-reference-specs

## Project Overview

This is a **Gherkin specification suite** for the `yaml-reference-cli` tool using Go and the `godog` BDD framework. The repository defines the expected behavior of YAML reference compilation through feature files, which are executed as integration tests against any CLI implementation.

The project **does not contain the CLI itself**—it's a test harness that validates that different language implementations (Python, TypeScript, etc.) conform to the specification.

**For a quick reference, see [AGENTS.md](../AGENTS.md).**

## Build & Test Commands

### Installation
```bash
go mod tidy
```

### Running Tests
All tests require the `YAML_REFERENCE_CLI_EXECUTABLE` environment variable pointing to the CLI binary being tested:

```bash
# Run full test suite against a CLI binary
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yaml-reference-cli
go run .

# Run using make (uses /usr/bin/echo as a dummy CLI for testing)
make test-echo

# Install as a binary and run
go install github.com/dsillman2000/yaml-reference-specs@latest
yaml-reference-specs
```

### Format Options
The `godog` test runner supports multiple output formats via the `-format` flag:
```bash
go run . -format pretty       # Default: colored terminal output
go run . -format junit        # JUnit XML for CI/CD
go run . -format json         # JSON output
```

## Key YAML Tags & Behaviors

Before diving into architecture, understand what the spec tests:

| Tag | Behavior | Notes |
|-----|----------|-------|
| `!reference` | Import file content; supports `path` + optional `anchor` | Cannot target multi-doc YAML files; anchor resolves locally only |
| `!reference-all` | Import files matching glob pattern into array | Returns empty array if no matches; supports multi-doc YAML |
| `!merge` | Shallow merge objects, last-write-wins semantics | Not YAML 1.1 first-write-wins; flattens nested sequences before merging |
| `!flatten` | Recursively flatten nested arrays to single level | Applied only to tagged node, not entire document |
| `!ignore` | Suppress node from output, preserve internal anchors | Allows embedding anchors without outputting the container |

## Path Restrictions (Security Model)

All file references are restricted **relative to the input file's root directory**:

- ✅ **Allowed:** References within same directory or subdirectories (`subdir/file.yaml`)
- ❌ **Blocked:** Upward traversal (`../../../etc/passwd`)
- ❌ **Blocked:** Absolute paths (`/etc/passwd`) — unless explicitly allowed via `--allow` flag
- ❌ **Blocked:** Symlinks that escape outside root directory

**Important:** Glob patterns matching disallowed paths silently omit those files (no error thrown).

## CLI Requirements

- **Exit Codes:** `0` on success, `1` on any error
- **JSON Output:** Keys must be sorted alphabetically at all nesting levels
- **Environment Variable:** `YAML_REFERENCE_CLI_EXECUTABLE` must be set and point to valid binary
  - Tests panic if missing
  - Tests panic if file doesn't exist

## Important Implementation Notes

- Anchors and aliases resolve only **within the file they're defined in** (not cross-file)
- Feature files are **embedded in the binary** via `//go:embed` — no external reads during tests
- **Multi-document YAML:**
  - `!reference` cannot target multi-doc files (error condition)
  - `!reference-all` can target multi-doc files (chains documents into result array)
- **Glob patterns:** Files matching disallowed paths are silently omitted (not an error)

## Architecture

**Scenario Test Framework** (`main.go`)
- Contains the `godog` scenario initialization and step definitions
- Each scenario runs in an isolated temporary directory (cleaned up after each test)
- Tests execute the CLI binary specified by `YAML_REFERENCE_CLI_EXECUTABLE` and validate exit codes and output

**Feature Files** (`features/`)
- `cli-api.feature` - Core CLI behavior (I/O, return codes, error handling)
- `reference/` - `!reference` tag scenarios
- `reference-all/` - `!reference-all` tag scenarios (glob patterns)
- `flatten/` - `!flatten` tag scenarios (array flattening)
- `merge/` - `!merge` tag scenarios (object merging with last-write-wins semantics)

### Test Context Flow

1. Each scenario gets a unique temporary directory (`testContext.tempDir`)
2. Step definitions manipulate files in this directory
3. The CLI is executed from this directory
4. Output is captured and compared against expected results
5. Cleanup occurs automatically after each scenario

## Key Conventions

### Step Definitions
The codebase uses Gherkin step patterns that map to Go functions:

```go
ctx.Step(`^I provide input YAML:$`, iProvideInputYaml)           // DocString argument
ctx.Step(`^I create a file "([^"]*)" with content:$`, ...)       // String argument + DocString
ctx.Step(`^the return code shall be (\d+)$`, returnCodeShallBe)  // Integer argument
```

New steps should follow the existing patterns and reuse the shared `testContext` struct.

### Important Context Values

- `testContext.tempDir` - The working directory for the test scenario
- `testContext.yamlReferenceCliArgs` - Contains input YAML, directory, allowed paths, expected output
- `testContext.output` - Captured stdout/stderr from CLI execution
- `testContext.returnCode` - Exit code from CLI execution

### Adding New Features/Steps

1. Create a `.feature` file in the appropriate subdirectory under `features/`
2. Use existing step definitions if possible
3. If new steps are needed, add them in `main.go`:
   - Implement the step function (takes `context.Context` and arguments)
   - Register it in `InitializeScenario` using `ctx.Step()`
   - Always retrieve `testCtx := ctx.Value("testContext").(*testContext)` at the start

### File Path Handling

- All test file paths are relative to `testContext.tempDir`
- The `runYamlReferenceCompile()` function converts relative paths to absolute when building CLI arguments
- The `--allow` flag requires absolute paths for security validation
- Use `filepath.Join()` and `filepath.Abs()` to handle path resolution correctly

### CLI Arguments

The test framework builds CLI arguments dynamically:
```bash
yaml-reference-cli <input-file> [--allow <absolute-path>] [--allow <absolute-path>] ...
```

The input file path is relative to the temp directory; allowed paths are absolute.

## Key Files to Understand

- `main.go` - Entry point, scenario setup, step definitions, context management
- `features/cli-api.feature` - Start here to understand basic expected behavior
- `features/reference/` - Understand `!reference` tag semantics
- `features/README.md` - Comprehensive specification of all tags and behaviors

## Notes

- Scenarios are isolated: each one gets a fresh temp directory that's automatically cleaned
- The embedded `embeddedFeatures` FS variable loads feature files directly into the binary
- Output from the CLI is compared as trimmed strings; formatting matters for assertions
- Error handling: the CLI should return exit code 1 on any error, 0 on success
- JSON output keys must be sorted alphabetically at all nesting levels (validated by assertions)
- Anchors and aliases can only be resolved within the file they're defined (see Path Restrictions above)
- For quick reference on project scope and requirements, see [AGENTS.md](../AGENTS.md)
