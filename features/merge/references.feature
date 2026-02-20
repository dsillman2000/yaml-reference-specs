Feature: !merge tag shall support merging objects from !reference and !reference-all tags.

  Scenario: Merge a referenced object with local overrides.
    Given I create a file "defaults.yaml" with content:
      """
      default_key: default_value
      override_key: original
      """
    And I provide input YAML:
      """
      result: !merge
        - !reference { path: defaults.yaml }
        - { override_key: custom }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "default_key": "default_value",
          "override_key": "custom"
        }
      }
      """

  Scenario: Merge multiple referenced objects with last-write-wins.
    Given I create a file "base.yaml" with content:
      """
      a: 1
      b: 2
      """
    And I create a file "overrides.yaml" with content:
      """
      b: 3
      c: 4
      """
    And I provide input YAML:
      """
      result: !merge
        - !reference { path: base.yaml }
        - !reference { path: overrides.yaml }
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

  Scenario: Merge a !reference-all result directly — !merge internally flattens the sequence of objects.
    Given I create a file "overrides/a.yaml" with content:
      """
      a_key: a_value
      """
    And I create a file "overrides/b.yaml" with content:
      """
      b_key: b_value
      """
    And I provide input YAML:
      """
      result: !merge
        - { base: true }
        - !reference-all { glob: "overrides/*.yaml" }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "result": {
          "a_key": "a_value",
          "b_key": "b_value",
          "base": true
        }
      }
      """

  Scenario: Merge a !reference-all whose files contain overlapping keys uses last-write-wins.
    Given I create a file "layers/base.yaml" with content:
      """
      host: localhost
      port: 3000
      """
    And I create a file "layers/prod.yaml" with content:
      """
      host: prod.example.com
      tls: true
      """
    And I provide input YAML:
      """
      config: !merge
        - !reference-all { glob: "layers/*.yaml" }
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "config": {
          "host": "prod.example.com",
          "port": 3000,
          "tls": true
        }
      }
      """
