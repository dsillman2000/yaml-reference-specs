Feature: !ignore tag correctly omits nodes from the output.

  Scenario: A map key with an !ignore value is omitted entirely.
    Given I provide input YAML:
      """
      a: 1
      b: !ignore 2
      c: 3
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "a": 1,
        "c": 3
      }
      """

  Scenario: A list item containing !ignore is omitted entirely.
    Given I provide input YAML:
      """
      items:
        - 1
        - !ignore 2
        - 3
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "items": [
          1,
          3
        ]
      }
      """

  Scenario: A nested structure with an !ignore value is pruned before children.
    Given I provide input YAML:
      """
      parent: !ignore
        child: 1
      sibling: 2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "sibling": 2
      }
      """

  Scenario: Nested !ignore inside !ignore does not fail.
    Given I provide input YAML:
      """
      parent: !ignore
        child: !ignore 1
      sibling: 2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "sibling": 2
      }
      """
