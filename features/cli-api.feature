Feature: yaml-reference-cli does not modify target files not containing any !reference tags

  Scenario: Compiling a file without !reference tags leaves it unchanged, but converts to JSON
    Given I provide input YAML:
      """
      key1: value1
      key2:
      - item1
      - item2
      """
    And I run yaml-reference-cli
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
    And I run yaml-reference-cli
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

  Scenario: Malformed YAML input shall raise an error
    Given I provide input YAML:
      """
      { invalid: [ json: mapping }
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

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
    And I run yaml-reference-cli
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
      
  Scenario: A YAML file with only a comment resolves to null
    Given I provide input YAML:
      """
      # This is just a comment
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      null
      """

  Scenario: A multi-document root input file is compiled as an array of documents, with !ignored documents dropped.
    Given I create a file "ref.yaml" with content:
      """
      ref-value: 42
      """
    And I create a file "subdocs.yaml" with content:
      """
      sub-doc-1: !reference ref.yaml
      ---
      duped:
        - &data !reference ref.yaml
        - *data
      """
    And I provide input YAML:
      """
      v: 1
      data: !reference ref.yaml
      sub-docs: !reference-all subdocs.yaml
      ---
      .anchors: !ignore
        something: &something unused
      ---
      !ignore
      Totally Ignored document! Nothing in here matters.
      ---
      flat: !flatten
        - [1, 2, 3]
        - 4
      ---
      merge: !merge
        - a: 1
          b: 2
        - b: 3
          c: 4
      """
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      [
        {
          "data": {
            "ref-value": 42
          },
          "sub-docs": [
            {
              "sub-doc-1": {
                "ref-value": 42
              }
            },
            {
              "duped": [
                {
                  "ref-value": 42
                },
                {
                  "ref-value": 42
                }
              ]
            }
          ],
          "v": 1
        },
        {},
        {
          "flat": [
            1,
            2,
            3,
            4
          ]
        },
        {
          "merge": {
            "a": 1,
            "b": 3,
            "c": 4
          }
        }
      ]
      """
