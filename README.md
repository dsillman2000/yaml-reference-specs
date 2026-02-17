yaml-reference-specs
====================

This repository is a Gherkin specification suite for the behavior of a modular YAML reference compilation CLI called `yaml-reference-cli`.

Some of the projects which conform to this specification include:

| Project | Compliance status | Link |
| --- | --- | --- |
| yaml-reference (Python) | ✅ | [Github](https://github.com/dsillman2000/yaml-reference) \| [PyPI](https://pypi.org/project/yaml-reference/) |
| yaml-reference-ts (TypeScript) | ✅ | [Github](https://github.com/dsillman2000/yaml-reference-ts) \| [npm](https://www.npmjs.com/package/@dsillman2000/yaml-reference-ts) |

Purpose
-------
> The CLI provides a language-agnostic framework for being able to assess the functionality of client libraries which implement the behavior of resolving YAML files which reference other YAML files (using `!reference` + `!reference-all` syntax).

- Describe the expected behavior of `yaml-reference-cli` using human-readable feature files under `features/`.
- Drive regression tests for the CLI implementation via Go tests that use the `godog` framework.

The specification has a basic [README](./features/README.md) describing the responsibilities of YAML reference resolution.

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
