Feature: !ignore nodes yield null when specifically aliased or referenced elsewhere, like empty files.

  Scenario: An alias to an !ignore anchor is omitted from the output.
    Given I provide input YAML:
      """
      definitions:
        - &secret !ignore hidden_value
      public_data: *secret
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "definitions": []
      }
      """

  Scenario: A map value alias to an !ignore object is omitted from the output.
    Given I provide input YAML:
      """
      anchors:
        - &secret !ignore
          a: 1
      b: *secret
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "anchors": []
      }
      """

  Scenario: Anchors defined inside an !ignored node can still be referenced elsewhere.
    Given I provide input YAML:
      """
      anchors: !ignore
        - &data
          a: aye
          b: 2
        - &more [m, o, r, e]
      Simple:
        data: *data
        more:
          letters: *more
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "Simple": {
          "data": {
            "a": "aye",
            "b": 2
          },
          "more": {
            "letters": [
              "m",
              "o",
              "r",
              "e"
            ]
          }
        }
      }
      """
