yaml-reference-specs
====================

This repository is a Gherkin specification suite for the behavior of a modular YAML compilation CLI called `yref-compile`.

Purpose
-------
- Describe the expected behavior of `yref-compile` using human-readable feature files under `features/`.
- Drive regression tests for the CLI implementation via Go tests that use the `godog` framework.

Repository layout
-----------------
- `features/` — Gherkin feature files exercising scenarios (input modes, file references, nested references, etc.).
- `*.go` and `*_test.go` — test step implementations and Godog test harness.

Running the tests
-----------------
1. Build or make available the `yref-compile` CLI binary you want to verify.
2. Set the environment variable `YAML_REFERENCE_CLI_EXECUTABLE` to the absolute path of that binary.

Quick run (from repository root):

```bash
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yref-compile
go test ./...
```

Alternatively, if you prefer to run features via the `godog` runner install it and run:

```bash
go install github.com/cucumber/godog/cmd/godog@latest
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yref-compile
godog
```

Python implementation with yaml-reference
--------------------------------------
This specification suite is also used to verify the behavior of the `yaml-reference` Python package, which provides similar YAML reference resolution functionality. To run the tests against the Python implementation, install the package from the local `pyproject.toml` using `uv`:

```bash
uv sync
```

This puts a copy of the `yref-compile` binary in `.venv/bin`, which allows you to run the test specs using `godog` via

```bash
YAML_REFERENCE_CLI_EXECUTABLE=$(pwd)/.venv/bin/yref-compile go test
```

Notes
-----
- Each scenario runs in an isolated temporary directory; file-creation steps place files in that temp directory so tests do not modify your working tree.
- Step implementations live in `yaml_reference_specs_tests.go` and include helpers for creating files, asserting file contents, providing stdin, and running the CLI.

Contributing
------------
- Add feature files under `features/` to describe new behaviors.
- Add corresponding step implementations or extend existing steps in the test file when needed.
