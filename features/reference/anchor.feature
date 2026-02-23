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
