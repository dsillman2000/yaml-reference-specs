yaml-reference-specs
====================

This repository is a Gherkin specification suite for the behavior of a modular YAML reference compilation CLI called `yaml-reference-cli`.

Purpose
-------
- Describe the expected behavior of `yaml-reference-cli` using human-readable feature files under `features/`.
- Drive regression tests for the CLI implementation via Go tests that use the `godog` framework.

Repository layout
-----------------
- `features/` — Gherkin feature files exercising scenarios (input modes, file references, nested references, etc.).
- `*.go` and `*_test.go` — test step implementations and Godog test harness.

Running the tests
-----------------
1. Build or make available the `yaml-reference-cli` CLI binary you want to verify.
2. Set the environment variable `YAML_REFERENCE_CLI_EXECUTABLE` to the absolute path of that binary.

Quick run (from repository root):

```bash
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yaml-reference-cli
go test
```

Alternatively, if you prefer to run features via the `godog` runner install it and run:

```bash
go install github.com/cucumber/godog/cmd/godog@latest
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yaml-reference-cli
godog
```

Notes
-----
- Each scenario runs in an isolated temporary directory; file-creation steps place files in that temp directory so tests do not modify your working tree.
- Step implementations live in `yaml_reference_specs_tests.go` and include helpers for creating files, asserting file contents, providing stdin, and running the CLI.

Contributing
------------
- Add feature files under `features/` to describe new behaviors.
- Add corresponding step implementations or extend existing steps in the test file when needed.
