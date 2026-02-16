Feature: Trying to parse !reference-all tags should sometimes throw errors.

  Scenario: Compiling a file with !reference-all when no files match the glob shall raise an error.
    Given I provide input YAML:
      """
      items: !reference-all {glob: nonexistent-*.yml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: Compiling a file with !reference-all which globs itself shall raise an error.
    Given I provide input YAML:
      """
      items: !reference-all {glob: "*.yml"}
      """
    And I create a file "other.yaml" with content:
      """
      hello: WORLD
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

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
