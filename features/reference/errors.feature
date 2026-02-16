Feature: Trying to parse !reference tags should sometimes throw errors.

  Scenario: Compiling a file with !reference when the file does not exist shall raise an error.
    Given I provide input YAML:
      """
      item: !reference {path: nonexistent.yml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: Compiling a file with !reference to itself shall raise an error.
    # By default, the input yaml is called "input.yaml."
    Given I provide input YAML:
      """
      item: !reference {path: input.yaml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: Compiling a file graph with a cycle of referential dependencies shall raise an error.
    Given I provide input YAML:
      """
      item: !reference {path: item2.yaml}
      """
    And I create a file "item2.yaml" with content:
      """
      item: !reference {path: item3.yaml}
      """
    And I create a file "item3.yaml" with content:
      """
      item: !reference {path: input.yaml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
