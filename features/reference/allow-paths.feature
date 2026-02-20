Feature: Paths may be explicitly allowed, otherwise restrictive default access control is applied on all references.

  Scenario: You cannot specify absolute paths in !reference tags.
    Given I provide input YAML:
      """
      malicious: !reference {path: /etc/passwd}
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: You cannot navigate out of the directory containing the root input YAML file.
    Given I provide input YAML:
      """
      stolen: !reference {path: ../secret/my-secrets.yaml}
      """
    And the input YAML is in a directory "root"
    And I create a file "secret/my-secrets.yaml" with content:
      """
      secret: password123
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: You can navigate backwards from within a reference.
    Given I provide input YAML:
      """
      child: !reference {path: child/other.yaml}
      """
    And I create a file "sibling.yaml" with content:
      """
      hi: data
      """
    And I create a file "child/other.yaml" with content:
      """
      name: Child Childson
      back-ref:
        sibling: !reference {path: ../sibling.yaml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      {
        "child": {
          "back-ref": {
            "sibling": {
              "hi": "data"
            }
          },
          "name": "Child Childson"
        }
      }
      """

  Scenario: You cannot navigate out of the root directory from within a reference.
    Given I provide input YAML:
      """
      ext: !reference {path: external.yaml}
      """
    And the input YAML is in a directory "root"
    And I create a file "root/external.yaml" with content:
      """
      secrets: !reference {path: ../secret/my-secrets.yaml}
      """
    And I create a file "secret/my-secrets.yaml" with content:
      """
      secret: password123
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: You cannot navigate out of the root directory from within a reference, even using a symlink.
    Given I provide input YAML:
      """
      ext: !reference {path: local-external/secret.yaml}
      """
    And the input YAML is in a directory "root"
    And I create a file "external/secret.yaml" with content:
      """
      secret: password123
      """
    And I create a symlink "root/local-external" pointing to "external"
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: You may explicitly allow paths outside of the root directory to be resolved from a reference.
    Given I provide input YAML:
      """
      project: !reference {path: ../project/info.yaml}
      stack: [mongodb, express, react, node]
      """
    And the input YAML is in a directory "application"
    And I create a file "project/info.yaml" with content:
      """
      name: My Project
      author: John Doe
      email: john.doe@example.com
      version: "1.0.0"
      """
    And I explicitly allow the path "project" to be resolved
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      {
        "project": {
          "author": "John Doe",
          "email": "john.doe@example.com",
          "name": "My Project",
          "version": "1.0.0"
        },
        "stack": [
          "mongodb",
          "express",
          "react",
          "node"
        ]
      }
      """

  Scenario: You may not access files in a sibling directory that shares the allowed path prefix.
    Given I provide input YAML:
      """
      dataset: !reference {path: ../example/data01.yaml}
      options:
        overwrite: true
      hacks: !reference {path: ../examplesecrets/my-super-secret-file.yaml}
      """
    And the input YAML is in a directory "application"
    And I create a file "example/data01.yaml" with content:
      """
      unit: "celsius"
      measurements: [24.0, 23.5, 24.5]
      """
    And I create a file "examplesecrets/my-super-secret-file.yaml" with content:
      """
      password: correct-horse-battery-staple
      """
    And I explicitly allow the path "example" to be resolved
    And I run yaml-reference-cli
    Then the return code shall be 1