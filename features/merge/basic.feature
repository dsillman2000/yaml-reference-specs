Feature: !merge tag merges a sequence of objects using last-write-wins semantics (like JS spread).

  Scenario: Merge two objects with overlapping keys uses last-write-wins.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1, b: 2 }
        - { b: 3, c: 4 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 1,
          "b": 3,
          "c": 4
        }
      }
      """

  Scenario: Merge two objects with no overlapping keys combines all keys.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1, b: 2 }
        - { c: 3, d: 4 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 1,
          "b": 2,
          "c": 3,
          "d": 4
        }
      }
      """

  Scenario: Merge three objects applies last-write-wins across all.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - { a: 2, b: 1 }
        - { a: 3, c: 1 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 3,
          "b": 1,
          "c": 1
        }
      }
      """

  Scenario: Merge a single object passes through unchanged.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1, b: 2 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 1,
          "b": 2
        }
      }
      """

  Scenario: Merge an empty sequence yields an empty object.
    Given I provide input YAML:
      """
      result: !merge []
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {}
      }
      """

  Scenario: A null value in a later object overrides an earlier non-null value.
    Given I provide input YAML:
      """
      result: !merge
        - { a: "value", b: "keep" }
        - { a: null }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": null,
          "b": "keep"
        }
      }
      """

  Scenario: Merge is shallow - nested objects are replaced entirely, not deep-merged.
    Given I provide input YAML:
      """
      result: !merge
        - { config: { retries: 3, timeout: 10 } }
        - { config: { timeout: 30 } }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "config": {
            "timeout": 30
          }
        }
      }
      """

  Scenario: !merge internally flattens nested sequences of objects before merging.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - - { b: 2 }
          - { c: 3 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 1,
          "b": 2,
          "c": 3
        }
      }
      """

  Scenario: !merge internally flattens deeply nested sequences of objects before merging.
    Given I provide input YAML:
      """
      result: !merge
        - { a: 1 }
        - [[{ b: 2 }], [{ c: 3 }]]
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 1,
          "b": 2,
          "c": 3
        }
      }
      """

  Scenario: Nested !merge tags resolve inner merge before outer merge.
    Given I provide input YAML:
      """
      result: !merge
        - a: 1
          inner: !merge
            - { x: 1, y: 1 }
            - { x: 2 }
        - { b: 2 }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a": 1,
          "b": 2,
          "inner": {
            "x": 2,
            "y": 1
          }
        }
      }
      """

  Scenario: An anchored !merge node can be aliased to duplicate its merged result.
    Given I provide input YAML:
      """
      merged: !merge &m
        - { a: 1, b: 2 }
        - { b: 3, c: 4 }
      data:
        copy: *m
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "data": {
          "copy": {
            "a": 1,
            "b": 3,
            "c": 4
          }
        },
        "merged": {
          "a": 1,
          "b": 3,
          "c": 4
        }
      }
      """

  Scenario: Aliases can be used as arguments within a !merge node.
    Given I provide input YAML:
      """
      defaults: &defaults
        host: localhost
        port: 3000
      overrides: &overrides
        port: 8080
        debug: true
      result: !merge
        - *defaults
        - *overrides
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "defaults": {
          "host": "localhost",
          "port": 3000
        },
        "overrides": {
          "debug": true,
          "port": 8080
        },
        "result": {
          "debug": true,
          "host": "localhost",
          "port": 8080
        }
      }
      """
