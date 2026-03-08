Feature: !ignore tag edge cases behave seamlessly like empty files.

  Scenario: A document whose root is !ignore evaluates to null.
    Given I provide input YAML:
      """
      !ignore
      a: 1
      b: 2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      null
      """

  Scenario: A sequence of exclusively !ignore elements yields an empty JSON array.
    Given I provide input YAML:
      """
      items:
        - !ignore 1
        - !ignore 2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "items": []
      }
      """

  Scenario: A map of exclusively !ignore elements yields an empty JSON object.
    Given I provide input YAML:
      """
      map:
        a: !ignore 1
        b: !ignore 2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "map": {}
      }
      """
