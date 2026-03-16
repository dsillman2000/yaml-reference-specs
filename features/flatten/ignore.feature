Feature: !flatten tag shall exclude !ignored items from the flattened result.

  Scenario: An !ignored item in a !flatten sequence is excluded from the output.
    Given I provide input YAML:
      """
      item: !flatten
        - [1, 2]
        - !ignore [3, 4]
        - [5, 6]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "item": [
          1,
          2,
          5,
          6
        ]
      }
      """

  Scenario: Multiple !ignored items in a !flatten sequence are all excluded.
    Given I provide input YAML:
      """
      item: !flatten
        - [1, 2]
        - !ignore [3, 4]
        - !ignore [5, 6]
        - [7, 8]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "item": [
          1,
          2,
          7,
          8
        ]
      }
      """

  Scenario: An !ignored scalar item in a !flatten sequence is excluded.
    Given I provide input YAML:
      """
      item: !flatten
        - [1, 2]
        - !ignore 3
        - [4, 5]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "item": [
          1,
          2,
          4,
          5
        ]
      }
      """
