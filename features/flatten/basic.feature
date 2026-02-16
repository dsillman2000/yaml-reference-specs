Feature: !flatten tag flattens basic YAML sequence-of-sequences.

  Scenario: Flattening an already-flattened sequence shall not change the input.
    Given I provide input YAML:
      """
      item: !flatten [1, 2, 3]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "item": [
          1,
          2,
          3
        ]
      }
      """

  Scenario: Flatten a very deep list
    Given I provide input YAML:
      """
      item: !flatten [[[[[1, 2]]]]]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "item": [
          1,
          2
        ]
      }
      """

  Scenario: Flattening a 2D sequence shall yield a 1D sequence.
    Given I provide input YAML:
      """
      item: !flatten [[1, 2], [3, 4], [5, 6]]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "item": [
          1,
          2,
          3,
          4,
          5,
          6
        ]
      }
      """

  Scenario: Flatten a sequence of variable-depth sequences.
    Given I provide input YAML:
      """
      item: !flatten [[[[1, 2]], [3, [4]]], [[5, 6]], [7]]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "item": [
          1,
          2,
          3,
          4,
          5,
          6,
          7
        ]
      }
      """
