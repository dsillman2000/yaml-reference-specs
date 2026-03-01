Feature: !flatten tag shall report errors when applied to non-sequence types.

  Scenario: !flatten on a string scalar causes an error.
    Given I provide input YAML:
      """
      result: !flatten "invalid scalar"
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: !flatten on an integer scalar causes an error.
    Given I provide input YAML:
      """
      result: !flatten 42
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: !flatten on a boolean scalar causes an error.
    Given I provide input YAML:
      """
      result: !flatten true
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: !flatten on a mapping causes an error.
    Given I provide input YAML:
      """
      result: !flatten
        key: value
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: !flatten on a null value causes an error.
    Given I provide input YAML:
      """
      result: !flatten null
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
