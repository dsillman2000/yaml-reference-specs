Feature: !merge tag shall report errors when any item, after internal recursive flattening, is not an object, or when the tag is applied directly to a non-sequence type.

  Scenario: A scalar value in the merge sequence causes an error.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - "not an object"
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: A sequence containing a scalar causes an error after internal flattening.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - [1, 2, 3]
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: A deeply nested sequence containing a scalar causes an error after internal flattening.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - [[["deep scalar"]]]
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: !merge applied directly to a scalar value causes an error.
    Given I provide input YAML:
      """
      result: !merge "unsupported scalar"
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: !merge applied directly to a mapping causes an error.
    Given I provide input YAML:
      """
      result: !merge
        key1: value1
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: !merge applied directly to a null value causes an error.
    Given I provide input YAML:
      """
      result: !merge null
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: A mixed sequence of objects and scalars causes an error after internal flattening.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - [{ b: 2 }, "not an object"]
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
