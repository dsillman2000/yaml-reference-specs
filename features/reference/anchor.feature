Feature: !reference tag supports the "anchor" argument

  Scenario: Using anchor argument extracts a scalar value anchored in the referenced file
    Given I create a file "child.yaml" with content:
      """
      name: &name David
      age: &age 25
      """
    And I provide input YAML:
      """
      child_name: !reference {path: child.yaml, anchor: name}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "child_name": "David"
      }
      """

  Scenario: Using anchor argument extracts a numeric value anchored in the referenced file
    Given I create a file "child.yaml" with content:
      """
      name: &name David
      age: &age 25
      """
    And I provide input YAML:
      """
      child_age: !reference {path: child.yaml, anchor: age}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "child_age": 25
      }
      """

  Scenario: Using anchor argument extracts a mapping value anchored in the referenced file
    Given I create a file "data.yaml" with content:
      """
      config: &cfg
        host: localhost
        port: 5432
      other: value
      """
    And I provide input YAML:
      """
      db: !reference {path: data.yaml, anchor: cfg}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "db": {
          "host": "localhost",
          "port": 5432
        }
      }
      """

  Scenario: Using anchor argument with block style extracts the anchored value
    Given I create a file "child.yaml" with content:
      """
      name: &name David
      age: &age 25
      """
    And I provide input YAML:
      """
      child_name: !reference
        path: child.yaml
        anchor: name
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "child_name": "David"
      }
      """

  Scenario: Using anchor argument extracts a value whose anchor is itself a !merge result
    Given I create a file "template.yaml" with content:
      """
      base: &base_config
        project: Demo
      config: &config !merge
        - *base_config
        - environment: production
      """
    And I provide input YAML:
      """
      template: !reference {path: template.yaml, anchor: config}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "template": {
          "environment": "production",
          "project": "Demo"
        }
      }
      """

  Scenario: Providing a non-existent anchor to !reference shall raise an error
    Given I create a file "child.yaml" with content:
      """
      name: &name David
      age: &age 25
      """
    And I provide input YAML:
      """
      child_name: !reference {path: child.yaml, anchor: nonexistent}
      """
    When I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: Using anchor argument extracts a value containing aliases to merge-produced anchors
    Given I create a file "a.yaml" with content:
      """
      .dat:
        c: &c 100

      a: !merge
        - foo: &fooVal !merge
          - {a: 10}
          - {b: *c}

      b: &val
        fooFromA: *fooVal
      """
    And I provide input YAML:
      """
      value:
        data: !reference
          path: a.yaml
          anchor: val
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "value": {
          "data": {
            "fooFromA": {
              "a": 10,
              "b": 100
            }
          }
        }
      }
      """

  Scenario: Anchored scalars of null, boolean, and empty string types are extracted faithfully
    Given I create a file "scalars.yaml" with content:
      """
      nothing: &nullVal null
      flag: &boolVal true
      blank: &emptyStr ""
      """
    And I provide input YAML:
      """
      a: !reference {path: scalars.yaml, anchor: nullVal}
      b: !reference {path: scalars.yaml, anchor: boolVal}
      c: !reference {path: scalars.yaml, anchor: emptyStr}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "a": null,
        "b": true,
        "c": ""
      }
      """

  Scenario: Anchored empty containers and populated sequences are extracted correctly
    Given I create a file "containers.yaml" with content:
      """
      empty_map: &eMap {}
      empty_seq: &eSeq []
      items: &list [1, 2, 3]
      """
    And I provide input YAML:
      """
      a: !reference {path: containers.yaml, anchor: eMap}
      b: !reference {path: containers.yaml, anchor: eSeq}
      c: !reference {path: containers.yaml, anchor: list}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "a": {},
        "b": [],
        "c": [
          1,
          2,
          3
        ]
      }
      """

  Scenario: Root-level anchor and deeply nested anchor are both discoverable
    Given I create a file "depth.yaml" with content:
      """
      &root
      level1:
        level2:
          level3:
            secret: &deep 42
      """
    And I provide input YAML:
      """
      whole: !reference {path: depth.yaml, anchor: root}
      deep: !reference {path: depth.yaml, anchor: deep}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "deep": 42,
        "whole": {
          "level1": {
            "level2": {
              "level3": {
                "secret": 42
              }
            }
          }
        }
      }
      """

  Scenario: Anchor defined within an !ignore node can be referenced directly
    Given I create a file "config.yaml" with content:
      """
      hidden: !ignore
        secret: &api_key secret_value_123
      public: visible
      """
    And I provide input YAML:
      """
      api: !reference {path: config.yaml, anchor: api_key}
      """
    And I explicitly allow the path "config.yaml" to be resolved
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "api": "secret_value_123"
      }
      """

  Scenario: Anchor defined within deeply nested !ignore node can be referenced
    Given I create a file "secrets.yaml" with content:
      """
      vault: !ignore
        level1:
          level2:
            credentials: &password super_secret_pass
      """
    And I provide input YAML:
      """
      access: !reference {path: secrets.yaml, anchor: password}
      """
    And I explicitly allow the path "secrets.yaml" to be resolved
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "access": "super_secret_pass"
      }
      """

  Scenario: Multiple anchors within !ignore nodes can be referenced independently
    Given I create a file "data.yaml" with content:
      """
      internal: !ignore
        database:
          host: &db_host localhost
          port: &db_port 5432
      """
    And I provide input YAML:
      """
      hostname: !reference {path: data.yaml, anchor: db_host}
      portnumber: !reference {path: data.yaml, anchor: db_port}
      """
    And I explicitly allow the path "data.yaml" to be resolved
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "hostname": "localhost",
        "portnumber": 5432
      }
      """