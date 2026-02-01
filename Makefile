install:
	go mod tidy

test-echo:
	YAML_REFERENCE_CLI_EXECUTABLE=echo go test

build-py:
	uv sync

test-py:
	YAML_REFERENCE_CLI_EXECUTABLE=$$(pwd)/.venv/bin/yref-compile go test
