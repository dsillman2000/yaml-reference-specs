Feature: yref-compile does not modify target files not containing any !reference tags

  Scenario: Compiling a file without !reference tags leaves it unchanged, but converts to JSON
    Given I provide input YAML:
      """
      key1: value1
      key2:
      - item1
      - item2
      """
    And I run yref-compile with any I/O mode
    Then the output shall be:
      """
      {
        "key1": "value1",
        "key2": [
          "item1",
          "item2"
        ]
      }
      """

  Scenario: Anchors and aliases are handled by the compilation CLI.
    Given I provide input YAML:
      """
      key1: &anchor1 value1
      key2:
      - item1
      - item2
      - *anchor1
      """
    And I run yref-compile with any I/O mode
    Then the output shall be:
      """
      {
        "key1": "value1",
        "key2": [
          "item1",
          "item2",
          "value1"
        ]
      }
      """

  Scenario: Keys are sorted by the CLI in the JSON result
    Given I provide input YAML:
      """
      z: zee
      y: why
      x: ecks
      items:
      - group: a
        alnum: true
      - group: b
        alnum: false
      """
    And I run yref-compile with any I/O mode
    Then the output shall be:
      """
      {
        "items": [
          {
            "alnum": true,
            "group": "a"
          },
          {
            "alnum": false,
            "group": "b"
          }
        ],
        "x": "ecks",
        "y": "why",
        "z": "zee"
      }
      """
