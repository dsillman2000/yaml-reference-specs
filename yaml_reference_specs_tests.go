package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/cucumber/godog"
)

type YamlReferenceCliArgs struct {
	givenInput     string
	expectedOutput string
}

type CliIOMode int

const (
	StdinToStdout CliIOMode = iota
	StdinToOutputFile
	InputFileToStdout
	InputFileToOutputFile // 4
)

type testContext struct {
	yamlReferenceCliExecutable string
	yamlReferenceCliArgs       YamlReferenceCliArgs
	files                      map[string]string
	tempDir                    string
	returnCodes                []int
	outputs                    []string
}

func runYamlReferenceCompile(ctx context.Context, ioMode CliIOMode) error {
	testCtx := ctx.Value("testContext").(*testContext)

	if ioMode == InputFileToOutputFile || ioMode == InputFileToStdout {
		// Create input file in temp dir
		inputFilePath := filepath.Join(testCtx.tempDir, "input.yaml")
		if err := os.WriteFile(inputFilePath, []byte(testCtx.yamlReferenceCliArgs.givenInput), 0o644); err != nil {
			return fmt.Errorf("failed to write input file: %w", err)
		}
	}

	args := []string{}
	switch ioMode {
	case StdinToStdout:
		// No additional args needed
	case StdinToOutputFile:
		args = append(args, "-o", "output.yaml")
	case InputFileToStdout:
		args = append(args, "-i", "input.yaml")
	case InputFileToOutputFile:
		args = append(args, "-i", "input.yaml", "-o", "output.yaml")
	}

	yamlReferenceCliExecutable := testCtx.yamlReferenceCliExecutable

	// Execute yref-compile CLI with the provided arguments in the scenario temp dir
	cmd := exec.Command(yamlReferenceCliExecutable, args...)
	if testCtx.tempDir != "" {
		cmd.Dir = testCtx.tempDir
	}
	// Provide stdin to the command if set
	if ioMode == StdinToStdout || ioMode == StdinToOutputFile {
		cmd.Stdin = strings.NewReader(testCtx.yamlReferenceCliArgs.givenInput)
	}
	output, err := cmd.CombinedOutput()
	if cmd.ProcessState == nil {
		return fmt.Errorf("failed to start yref-compile command: %w", err)
	}
	testCtx.returnCodes[ioMode] = cmd.ProcessState.ExitCode()
	// Capture output based on IO mode
	if ioMode == StdinToStdout || ioMode == InputFileToStdout {
		testCtx.outputs[ioMode] = strings.TrimSpace(string(output))
	}
	if ioMode == StdinToOutputFile || ioMode == InputFileToOutputFile {
		// Read output file content
		outputFilePath := filepath.Join(testCtx.tempDir, "output.yaml")
		data, readErr := os.ReadFile(outputFilePath)
		if readErr != nil {
			return fmt.Errorf("failed to read output file: %w", readErr)
		}
		testCtx.outputs[ioMode] = strings.TrimSpace(string(data))
	}
	_ = err
	return nil
}

func iProvideInputYaml(ctx context.Context, arg1 *godog.DocString) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	testCtx.yamlReferenceCliArgs.givenInput = arg1.Content
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

func theOutputShallBe(ctx context.Context, arg1 *godog.DocString) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	expected := strings.TrimSpace(arg1.Content)
	testCtx.yamlReferenceCliArgs.expectedOutput = expected
	for ioMode := StdinToStdout; ioMode <= InputFileToOutputFile; ioMode++ {
		actual := strings.TrimSpace(testCtx.outputs[ioMode])
		if actual != expected {
			return fmt.Errorf("in IO mode %d, expected output to be %q, got %q", ioMode, expected, actual)
		}
	}
	return nil
}

func iRunYamlReferenceCompileWithAnyIOMode(ctx context.Context) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	// Run the CLI in all four IO modes
	for ioMode := StdinToStdout; ioMode <= InputFileToOutputFile; ioMode++ {
		if err := runYamlReferenceCompile(ctx, ioMode); err != nil {
			return fmt.Errorf("failed to run yref-compile in mode %d: %w", ioMode, err)
		}
	}
	return nil
}

func returnCodeShallBe(ctx context.Context, expectedCode int) error {
	testCtx := ctx.Value("testContext").(*testContext)
	if testCtx == nil {
		return fmt.Errorf("test context not found")
	}
	for ioMode := StdinToStdout; ioMode <= InputFileToOutputFile; ioMode++ {
		actualCode := testCtx.returnCodes[ioMode]
		if actualCode != expectedCode {
			return fmt.Errorf("in IO mode %d, expected return code %d, got %d", ioMode, expectedCode, actualCode)
		}
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
			returnCodes:                make([]int, 4),
			outputs:                    make([]string, 4),
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
	ctx.Step(`^I provide input YAML:$`, iProvideInputYaml)
	ctx.Step(`^the output shall be:$`, theOutputShallBe)
	ctx.Step(`^the return code shall be (\d+)$`, returnCodeShallBe)
	ctx.Step(`^I run yref-compile with any I/O mode$`, iRunYamlReferenceCompileWithAnyIOMode)
}
