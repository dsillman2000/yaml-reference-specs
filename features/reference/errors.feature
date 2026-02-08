Feature: !reference should sometimes throw errors.

  Scenario: Compiling a file with !reference when the file does not exist shall raise an error.
    Given I provide input YAML:
      """
      item: !reference {path: nonexistent.yml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: Compiling a file with !reference on a scalar value shall raise an error.
    Given I provide input YAML:
      """
      item: !reference "my/favorite/path.yaml"
      """
    And I create a file "my/favorite/path.yaml" with content:
      """
      even: if
      this: exists
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
