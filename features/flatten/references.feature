Feature: !flatten tag shall support flattening the results of !reference and !reference-all tags.

  Scenario: Flatten a sequence of objects, a reference, and a reference-all tag.
    Given I provide input YAML:
      """
      CONTENTS: !flatten
        - { name: object-1 }
        - { name: object-2 }
        - !reference { path: objects/3.yaml }
        - !reference-all { glob: "objects/v1/*.yaml" }
      """
    And I create a file "objects/3.yaml" with content:
      """
      name: object-3
      """
    And I create a file "objects/v1/object-4.yaml" with content:
      """
      - [{ name: object-4 }]
      """
    And I create a file "objects/v1/object-5.yaml" with content:
      """
      - [{ name: object-5 }]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "CONTENTS": [
          {
            "name": "object-1"
          },
          {
            "name": "object-2"
          },
          {
            "name": "object-3"
          },
          {
            "name": "object-4"
          },
          {
            "name": "object-5"
          }
        ]
      }
      """
