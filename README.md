# yaml-reference-specs

This repository is a Gherkin specification suite for the behavior of a modular YAML reference compilation CLI called `yaml-reference-cli`.

Some of the projects which conform to this specification include:

| Project                        | Compliance status | Link                                                                                                                                |
| ------------------------------ | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| yaml-reference (Python)        | ✅                | [Github](https://github.com/dsillman2000/yaml-reference) \| [PyPI](https://pypi.org/project/yaml-reference/)                        |
| yaml-reference-ts (TypeScript) | ✅                | [Github](https://github.com/dsillman2000/yaml-reference-ts) \| [npm](https://www.npmjs.com/package/@dsillman2000/yaml-reference-ts) |

Tags supported include:

- **`!reference`**: "Import" another YAML document from another file into the current node.
  - `path`: Relative path to the YAML file to "import."
- **`!reference-all`**: "Import" all YAML documents using a specific glob pattern into a sequence node.
  - `glob`: Relative glob pattern matching YAML files to "import."
- **`!merge`**: Merge a multiple objects into a single object, using a shallow merge.
- **`!flatten`**: "Flatten" a nested sequence of sequences into a one-dimensional sequence.

## Purpose

> The CLI provides a language-agnostic framework for being able to assess the functionality of client libraries which implement the behavior of resolving YAML files which reference other YAML files (using `!reference`, `!reference-all`, `!merge` and `!flatten` syntax).

- Describe the expected behavior of `yaml-reference-cli` using human-readable feature files under `features/`.
- Drive regression tests for the CLI implementation via Go tests that use the `godog` framework.

The specification has a basic [README](./features/README.md) describing the responsibilities of YAML reference resolution.

## Repository layout

- `features/` — Gherkin feature files exercising scenarios (input modes, file references, nested references, etc.).
- `main.go` - CLI entrypoint that runs the `godog` test suite against a specified `yaml-reference-cli` implementation supplied with the `YAML_REFERENCE_CLI_EXECUTABLE` environment variable.

## Running the tests

1. Build or make available the `yaml-reference-cli` CLI binary you want to verify.
2. Set the environment variable `YAML_REFERENCE_CLI_EXECUTABLE` to the absolute path of that binary.

If you have this project cloned on your machine, you can run the tests from this project directory with:

```bash
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yaml-reference-cli
go run .
```

Alternatively, you can run the test suite by installing it directly with `go install` and then running the `yaml-reference-specs` binary:

```bash
go install github.com/dsillman2000/yaml-reference-specs@latest
export YAML_REFERENCE_CLI_EXECUTABLE=/absolute/path/to/yaml-reference-cli
yaml-reference-specs
```

## Notes

- Each scenario runs in an isolated temporary directory; file-creation steps place files in that temp directory so tests do not modify your working tree.

## Contributing

- Add feature files under `features/` to describe new behaviors.
- Add corresponding step implementations or extend existing steps in the test file when needed.

## Acknowledgments

Author(s):

- David Sillman <dsillman2000@gmail.com>
- Ryan Johnson <github@ryodine.com>
