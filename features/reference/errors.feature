Feature: Trying to parse !reference tags should sometimes throw errors.

  Scenario: Compiling a file with !reference when the file does not exist shall raise an error.
    Given I provide input YAML:
      """
      item: !reference {path: nonexistent.yml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
