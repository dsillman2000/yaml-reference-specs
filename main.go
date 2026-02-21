package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/cucumber/godog"
	"github.com/cucumber/godog/colors"
)

type YamlReferenceCliArgs struct {
	givenInput     string
	expectedOutput string
	inputDirectory string
	allowPaths     []string
}

type testContext struct {
	yamlReferenceCliExecutable string
	yamlReferenceCliArgs       YamlReferenceCliArgs
	files                      map[string]string
	tempDir                    string
	returnCode                 int
	output                     string
}

func runYamlReferenceCompile(ctx context.Context) error {
	testCtx := ctx.Value("testContext").(*testContext)

	yamlReferenceCliExecutable := testCtx.yamlReferenceCliExecutable

	// Create input file in the specified directory (or root if not specified)
	inputDir := testCtx.tempDir
	if testCtx.yamlReferenceCliArgs.inputDirectory != "" {
		inputDir = filepath.Join(testCtx.tempDir, testCtx.yamlReferenceCliArgs.inputDirectory)
		if err := os.MkdirAll(inputDir, 0o755); err != nil {
			return fmt.Errorf("failed to create input directory %s: %w", testCtx.yamlReferenceCliArgs.inputDirectory, err)
		}
	}

	// Write input YAML content to file
	if testCtx.yamlReferenceCliArgs.givenInput != "" {
		inputPath := filepath.Join(inputDir, "input.yaml")
		if err := os.WriteFile(inputPath, []byte(testCtx.yamlReferenceCliArgs.givenInput), 0o644); err != nil {
			return fmt.Errorf("failed to write input file: %w", err)
		}
	}

	// Provide path to YAML document to the command
	inputPath := "input.yaml"
	if testCtx.yamlReferenceCliArgs.inputDirectory != "" {
		inputPath = filepath.Join(testCtx.yamlReferenceCliArgs.inputDirectory, "input.yaml")
	}
	args := []string{inputPath}

	// If explicit paths are allowed, add them to the command arguments
	if len(testCtx.yamlReferenceCliArgs.allowPaths) > 0 {
		for _, path := range testCtx.yamlReferenceCliArgs.allowPaths {
			// Resolve the path relative to the input directory
			resolvedPath, err := filepath.Abs(filepath.Join(testCtx.tempDir, path))
			if err != nil {
				return fmt.Errorf("failed to resolve path %s: %w", path, err)
			}
			args = append(args, "--allow", resolvedPath)
		}
	}

	// Execute yaml-reference-cli CLI with the provided arguments in the scenario temp dir
	cmd := exec.Command(yamlReferenceCliExecutable, args...)
	if testCtx.tempDir != "" {
		cmd.Dir = testCtx.tempDir
	}
	output, err := cmd.CombinedOutput()
	if cmd.ProcessState == nil {
		return fmt.Errorf("failed to start yaml-reference-cli command: %w", err)
	}
	testCtx.returnCode = cmd.ProcessState.ExitCode()
	// Capture output
	testCtx.output = strings.TrimSpace(string(output))
	return nil
}

func iProvideInputYaml(ctx context.Context, arg1 *godog.DocString) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	testCtx.yamlReferenceCliArgs.givenInput = arg1.Content
	// Don't create the file here - wait until we know the directory
	return nil
}

func iExplicitlyAllowPath(ctx context.Context, arg1 string) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	testCtx.yamlReferenceCliArgs.allowPaths = append(testCtx.yamlReferenceCliArgs.allowPaths, arg1)
	return nil
}

func iCreateFileWithContent(ctx context.Context, arg1 string, arg2 *godog.DocString) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	full := filepath.Join(testCtx.tempDir, arg1)
	if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
		return fmt.Errorf("failed to create directories for %s: %w", arg1, err)
	}
	if err := os.WriteFile(full, []byte(arg2.Content), 0o644); err != nil {
		return fmt.Errorf("failed to write file %s: %w", arg1, err)
	}
	testCtx.files[arg1] = arg2.Content
	return nil
}

func iCreateSymlink(ctx context.Context, symlinkPath, targetPath string) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	fullSymlinkPath := filepath.Join(testCtx.tempDir, symlinkPath)
	if err := os.MkdirAll(filepath.Dir(fullSymlinkPath), 0o755); err != nil {
		return fmt.Errorf("failed to create directories for %s: %w", symlinkPath, err)
	}
	// Create symlink
	if err := os.Symlink(targetPath, fullSymlinkPath); err != nil {
		return fmt.Errorf("failed to create symlink %s -> %s: %w", symlinkPath, targetPath, err)
	}
	return nil
}

func iProvideInputYamlInDirectory(ctx context.Context, directory string) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	testCtx.yamlReferenceCliArgs.inputDirectory = directory
	return nil
}

func theOutputShallBe(ctx context.Context, arg1 *godog.DocString) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	expected := strings.TrimSpace(arg1.Content)
	testCtx.yamlReferenceCliArgs.expectedOutput = expected
	actual := strings.TrimSpace(testCtx.output)
	if actual != expected {
		return fmt.Errorf("Expected output to be:\n\n%s\n\nGot:\n\n%s\n", expected, actual)
	}
	return nil
}

func iRunYamlReferenceCli(ctx context.Context) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	// Run the CLI with stdin
	if err := runYamlReferenceCompile(ctx); err != nil {
		return err
	}
	return nil
}

func returnCodeShallBe(ctx context.Context, expectedCode int) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	actualCode := testCtx.returnCode
	if actualCode != expectedCode {
		return fmt.Errorf("Expected return code %d, got %d", expectedCode, actualCode)
	}
	return nil
}

func InitializeScenario(ctx *godog.ScenarioContext) {
	// Read environment variable for $YAML_REFERENCE_CLI_EXECUTABLE
	yamlReferenceCliExecutable := os.Getenv("YAML_REFERENCE_CLI_EXECUTABLE")
	if yamlReferenceCliExecutable == "" {
		panic(fmt.Errorf("YAML_REFERENCE_CLI_EXECUTABLE environment variable not set"))
	}
	// Initialize base test context values; each scenario will get its own testContext
	baseExecutable := yamlReferenceCliExecutable

	ctx.Before(func(ctx context.Context, sc *godog.Scenario) (context.Context, error) {
		// Set up before each scenario with its own temp directory
		tempDir, err := os.MkdirTemp("", "yref-test-")
		if err != nil {
			return ctx, fmt.Errorf("failed to create temp dir: %w", err)
		}
		testCtx := &testContext{
			yamlReferenceCliExecutable: baseExecutable,
			files:                      make(map[string]string),
			tempDir:                    tempDir,
			returnCode:                 -1,
			output:                     "",
		}
		return context.WithValue(ctx, "testContext", testCtx), nil
	})

	ctx.After(func(ctx context.Context, sc *godog.Scenario, err error) (context.Context, error) {
		// Clean up scenario temp directory
		testCtx := ctx.Value("testContext").(*testContext)
		if testCtx != nil && testCtx.tempDir != "" {
			_ = os.RemoveAll(testCtx.tempDir)
		}
		return ctx, nil
	})
	ctx.Step(`^I create a file "([^"]*)" with content:$`, iCreateFileWithContent)
	ctx.Step(`^I create a symlink "([^"]*)" pointing to "([^"]*)"$`, iCreateSymlink)
	ctx.Step(`^I provide input YAML:$`, iProvideInputYaml)
	ctx.Step(`^the input YAML is in a directory "([^"]*)"$`, iProvideInputYamlInDirectory)
	ctx.Step(`^I explicitly allow the path "([^"]*)" to be resolved$`, iExplicitlyAllowPath)
	ctx.Step(`^the output shall be:$`, theOutputShallBe)
	ctx.Step(`^the return code shall be (\d+)$`, returnCodeShallBe)
	ctx.Step(`^I run yaml-reference-cli$`, iRunYamlReferenceCli)
}

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
		ScenarioInitializer: InitializeScenario,
		Options:             &opts,
	}.Run()

	os.Exit(status)
}
