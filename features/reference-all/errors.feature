Feature: Trying to parse !reference-all tags should sometimes throw errors.

  Scenario: Compiling a file with !reference-all when no files match the glob shall raise an error.
    Given I provide input YAML:
      """
      items: !reference-all {glob: nonexistent-*.yml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
