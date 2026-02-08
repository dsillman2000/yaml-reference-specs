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

	// Execute yref-compile CLI with the provided arguments in the scenario temp dir
	cmd := exec.Command(yamlReferenceCliExecutable)
	if testCtx.tempDir != "" {
		cmd.Dir = testCtx.tempDir
	}
	// Provide stdin YAML document to the command
	cmd.Stdin = strings.NewReader(testCtx.yamlReferenceCliArgs.givenInput)
	output, err := cmd.CombinedOutput()
	if cmd.ProcessState == nil {
		return fmt.Errorf("failed to start yref-compile command: %w", err)
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
	actual := strings.TrimSpace(testCtx.output)
	if actual != expected {
		return fmt.Errorf("Expected output to be:\n\n%s\n\nGot:\n\n%s\n", expected, actual)
	}
	return nil
}

func iRunYamlReferenceCompileWithAnyIOMode(ctx context.Context) error {
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
	ctx.Step(`^I provide input YAML:$`, iProvideInputYaml)
	ctx.Step(`^the output shall be:$`, theOutputShallBe)
	ctx.Step(`^the return code shall be (\d+)$`, returnCodeShallBe)
	ctx.Step(`^I run yref-compile with any I/O mode$`, iRunYamlReferenceCompileWithAnyIOMode)
}
