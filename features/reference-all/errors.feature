Feature: !reference-all circular reference detection

  Scenario: Compiling a !reference-all tag to a file which references it shall raise an error.
    Given I provide input YAML:
      """
      items: !reference-all {glob: "item/*.yml"}
      """
    And I create a file "item/a.yaml" with content:
      """
      item: A
      """
    And I create a file "item/b.yaml" with content:
      """
      item: B
      back: !reference {path: ../input.yaml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
