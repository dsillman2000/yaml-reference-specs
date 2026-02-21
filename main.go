package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/cucumber/godog"
	"github.com/cucumber/godog/colors"
	"github.com/dsillman2000/yaml-reference-specs/yaml_reference_specs"
)

func main() {
	var cliExecutable string
	if val, exists := os.LookupEnv("YAML_REFERENCE_CLI_EXECUTABLE"); exists {
		cliExecutable = val
	}

	// Parse command line flags
	format := flag.String("format", "pretty", "Format of output (pretty, junit, etc.)")
	flag.Parse()

	// Validate CLI executable
	if cliExecutable == "" {
		fmt.Fprintf(os.Stderr, "Error: YAML_REFERENCE_CLI_EXECUTABLE environment variable must be set\n")
		os.Exit(1)
	}

	if _, err := os.Stat(cliExecutable); err != nil {
		fmt.Fprintf(os.Stderr, "Error: CLI executable not found at %s: %v\n", cliExecutable, err)
		os.Exit(1)
	}

	// Configure godog options
	var opts = godog.Options{
		Output: colors.Colored(os.Stdout),
		Format: *format,
		Paths:  []string{"features"},
	}

	// Run the test suite
	status := godog.TestSuite{
		Name:                "yaml-reference CLI Test Suite",
		ScenarioInitializer: yaml_reference_specs.InitializeScenario,
		Options:             &opts,
	}.Run()

	os.Exit(status)
}
