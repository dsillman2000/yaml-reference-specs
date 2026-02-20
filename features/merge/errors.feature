Feature: !merge tag shall report errors when any item, after internal recursive flattening, is not an object.

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

  Scenario: A mixed sequence of objects and scalars causes an error after internal flattening.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - [{ b: 2 }, "not an object"]
      """
    And I run yaml-reference-cli
    Then the return code shall be 1
