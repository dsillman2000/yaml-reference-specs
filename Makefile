install:
	go mod tidy

test-echo:
	YAML_REFERENCE_CLI_EXECUTABLE=echo go run .
