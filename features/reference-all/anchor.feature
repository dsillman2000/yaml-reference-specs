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
