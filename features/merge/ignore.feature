Feature: !merge tag shall exclude !ignored items from the merged result.

  Scenario: An !ignored object in a !merge sequence is excluded from the merge.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1, b: 2 }
        - !ignore { b: 999, c: 3 }
        - { d: 4 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 1,
          "b": 2,
          "d": 4
        }
      }
      """

  Scenario: The first object in a !merge sequence is !ignored — remaining objects are still merged.
    Given I provide input YAML:
      """
      result: !merge
        - !ignore { a: 1, b: 2 }
        - { c: 3, d: 4 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "c": 3,
          "d": 4
        }
      }
      """

  Scenario: All objects in a !merge sequence are !ignored — result is an empty object.
    Given I provide input YAML:
      """
      result: !merge
        - !ignore { a: 1 }
        - !ignore { b: 2 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {}
      }
      """
