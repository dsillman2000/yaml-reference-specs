Feature: !reference-all tag supports the "anchor" argument

  Scenario: Using anchor argument extracts a scalar value anchored in each matched file
    Given I create a file "child-1.yaml" with content:
      """
      name: &name David
      age: &age 25
      """
    And I create a file "child-2.yaml" with content:
      """
      name: &name Alice
      age: &age 30
      """
    And I provide input YAML:
      """
      child_ages: !reference-all {glob: child-*.yaml, anchor: age}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "child_ages": [
          25,
          30
        ]
      }
      """

  Scenario: Using anchor argument extracts a string value anchored in each matched file
    Given I create a file "child-1.yaml" with content:
      """
      name: &name David
      age: &age 25
      """
    And I create a file "child-2.yaml" with content:
      """
      name: &name Alice
      age: &age 30
      """
    And I provide input YAML:
      """
      child_names: !reference-all {glob: child-*.yaml, anchor: name}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "child_names": [
          "David",
          "Alice"
        ]
      }
      """

  Scenario: Using anchor argument extracts a mapping value anchored in each matched file
    Given I create a file "service-1.yaml" with content:
      """
      config: &cfg
        host: db1.example.com
        port: 5432
      name: service-1
      """
    And I create a file "service-2.yaml" with content:
      """
      config: &cfg
        host: db2.example.com
        port: 5433
      name: service-2
      """
    And I provide input YAML:
      """
      configs: !reference-all {glob: service-*.yaml, anchor: cfg}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "configs": [
          {
            "host": "db1.example.com",
            "port": 5432
          },
          {
            "host": "db2.example.com",
            "port": 5433
          }
        ]
      }
      """

  Scenario: Using anchor argument with block style extracts the anchored value from each matched file
    Given I create a file "child-1.yaml" with content:
      """
      name: &name David
      age: &age 25
      """
    And I create a file "child-2.yaml" with content:
      """
      name: &name Alice
      age: &age 30
      """
    And I provide input YAML:
      """
      child_ages: !reference-all
        glob: child-*.yaml
        anchor: age
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "child_ages": [
          25,
          30
        ]
      }
      """

  Scenario: Providing a non-existent anchor to !reference-all shall raise an error
    Given I create a file "child-1.yaml" with content:
      """
      name: &name David
      age: &age 25
      _nonexistent: &nonexistent "my value"
      """
    And I create a file "child-2.yaml" with content:
      """
      name: &name Alice
      age: &age 30
      """
    And I provide input YAML:
      """
      child_ages: !reference-all {glob: child-*.yaml, anchor: nonexistent}
      """
    When I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: Anchored scalars of null, boolean, and empty string types are extracted faithfully
    Given I create a file "children/scalars.yaml" with content:
      """
      nothing: &nullVal null
      flag: &boolVal true
      blank: &emptyStr ""
      """
    And I provide input YAML:
      """
      a: !reference-all {glob: "children/scalars.yaml", anchor: nullVal}
      b: !reference-all {glob: "children/scalars.yaml", anchor: boolVal}
      c: !reference-all {glob: "children/scalars.yaml", anchor: emptyStr}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "a": [
          null
        ],
        "b": [
          true
        ],
        "c": [
          ""
        ]
      }
      """

  Scenario: Anchored empty containers and populated sequences are extracted correctly
    Given I create a file "children/containers.yaml" with content:
      """
      empty_map: &eMap {}
      empty_seq: &eSeq []
      items: &list [1, 2, 3]
      """
    And I provide input YAML:
      """
      a: !reference-all {glob: "children/containers.yaml", anchor: eMap}
      b: !reference-all {glob: "children/containers.yaml", anchor: eSeq}
      c: !reference-all {glob: "children/containers.yaml", anchor: list}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "a": [
          {}
        ],
        "b": [
          []
        ],
        "c": [
          [
            1,
            2,
            3
          ]
        ]
      }
      """

  Scenario: Root-level anchor and deeply nested anchor are both discoverable
    Given I create a file "children/depth.yaml" with content:
      """
      &root
      level1:
        level2:
          level3:
            secret: &deep 42
      """
    And I provide input YAML:
      """
      whole: !reference-all {glob: "children/depth.yaml", anchor: root}
      deep: !reference-all {glob: "children/depth.yaml", anchor: deep}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "deep": [
          42
        ],
        "whole": [
          {
            "level1": {
              "level2": {
                "level3": {
                  "secret": 42
                }
              }
            }
          }
        ]
      }
      """

  Scenario: Same anchor name across multiple matched files collects all values
    Given I create a file "children/alice.yaml" with content:
      """
      nothing: &nullVal null
      flag: &boolVal true
      """
    And I create a file "children/bob.yaml" with content:
      """
      nothing: &nullVal null
      flag: &boolVal false
      """
    And I provide input YAML:
      """
      nulls: !reference-all {glob: "children/*.yaml", anchor: nullVal}
      flags: !reference-all {glob: "children/*.yaml", anchor: boolVal}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "flags": [
          true,
          false
        ],
        "nulls": [
          null,
          null
        ]
      }
      """
