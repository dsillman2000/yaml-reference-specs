Feature: !reference tag basically functions

  Scenario: Compiling a file with !reference tags replaces them with the referenced content
        (flow, scalar substitution)

    Given I provide input YAML:
      """
      key1: !reference {path: data.yml}
      """
    And I create a file "data.yml" with content:
      """
      13.3
      ...
      """
    And I run yref-compile
    Then the output shall be:
      """
      {
        "key1": 13.3
      }
      """

  Scenario: Compiling a file with !reference tags replaces them with the referenced content
        (flow, structured substitution)

    Given I provide input YAML:
      """
      key1: !reference {path: data.yml}
      """
    And I create a file "data.yml" with content:
      """
      keyA: valueA
      keyB:
      - listItem1
      - listItem2
      """
    And I run yref-compile
    Then the output shall be:
      """
      {
        "key1": {
          "keyA": "valueA",
          "keyB": [
            "listItem1",
            "listItem2"
          ]
        }
      }
      """

  Scenario: Compiling a file with !reference tags replaces them with the referenced content
        (block, scalar substitution)

    Given I provide input YAML:
      """
      key1: !reference
        path: data.yml
      """
    And I create a file "data.yml" with content:
      """
      some long string value
      that spans multiple lines
      in the file.
      ...
      """
    And I run yref-compile
    Then the output shall be:
      """
      {
        "key1": "some long string value that spans multiple lines in the file."
      }
      """

  Scenario: Compiling a file with !reference tags replaces them with the referenced content
        (block, structured substitution)

    Given I provide input YAML:
      """
      key1: !reference
        path: data.yml
      """
    And I create a file "data.yml" with content:
      """
      keyA: valueA
      keyB:
      - listItem1
      - listItem2
      """
    And I run yref-compile
    Then the output shall be:
      """
      {
        "key1": {
          "keyA": "valueA",
          "keyB": [
            "listItem1",
            "listItem2"
          ]
        }
      }
      """

  Scenario: A file references two other files
    Given I create a file "subdir/item1.yaml" with content:
      """
      alpha: A
      """
    And I create a file "subdir/item2.yaml" with content:
      """
      beta: B
      """
    And I provide input YAML:
      """
      root:
      - !reference {path: subdir/item1.yaml}
      - !reference {path: subdir/item2.yaml}
      """
    When I run yref-compile
    Then the output shall be:
      """
      {
        "root": [
          {
            "alpha": "A"
          },
          {
            "beta": "B"
          }
        ]
      }
      """

  Scenario: A file duplicates a reference with anchors and aliases (though the anchors/aliases are not preserved)
    Given I create a file "names/new.yaml" with content:
      """
      BasicName
      ...
      """
    And I provide input YAML:
      """
      myItem: &it
        isItem: true
        name: !reference {path: names/new.yaml}
      values:
      - {isItem: false, name: base}
      - *it
      """
    When I run yref-compile
    Then the output shall be:
      """
      {
        "myItem": {
          "isItem": true,
          "name": "BasicName"
        },
        "values": [
          {
            "isItem": false,
            "name": "base"
          },
          {
            "isItem": true,
            "name": "BasicName"
          }
        ]
      }
      """
