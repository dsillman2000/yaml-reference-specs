Feature: Paths may be explicitly allowed, otherwise restrictive default access control is applied on all references.

  Scenario: You cannot specify absolute paths in !reference-all tags.
    Given I provide input YAML:
      """
      malicious: !reference-all {glob: /home/*/pwd-cfg.yaml}
      """
    And I run yaml-reference-cli
    # Not ideal:
    Then the return code shall be 1

  Scenario: You cannot navigate out of the directory containing the root input YAML file.
    Given I provide input YAML:
      """
      stolen: !reference-all {glob: ../secret/*.yaml}
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
      child: !reference-all {glob: child/*.yaml}
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
    And I create a file "child/another.yaml" with content:
      """
      name: Other Otherson
      back-ref:
        sibling: !reference {path: ../sibling.yaml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      {
        "child": [
          {
            "back-ref": {
              "sibling": {
                "hi": "data"
              }
            },
            "name": "Other Otherson"
          },
          {
            "back-ref": {
              "sibling": {
                "hi": "data"
              }
            },
            "name": "Child Childson"
          }
        ]
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
      secrets: !reference-all {glob: ../secret/*.yaml}
      """
    And I create a file "secret/my-secrets.yaml" with content:
      """
      secret: password123
      """
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: You may explicitly allow paths outside of the root directory to be resolved from a reference-all tag.
    Given I provide input YAML:
      """
      project: !reference-all {glob: ../project/*/info.yaml}
      stack: [mongodb, express, react, node]
      """
    And the input YAML is in a directory "application"
    And I create a file "project/sub-1/info.yaml" with content:
      """
      name: My Project
      author: John Doe
      email: john.doe@example.com
      version: "1.0.0"
      """
    And I create a file "project/sub-2/info.yaml" with content:
      """
      name: My Project 2
      author: John Doe 2
      email: john.doe2@example.com
      version: "2.0.0"
      """
    And I explicitly allow the path "project" to be resolved
    And I run yaml-reference-cli
    # Then the return code shall be 0
    And the output shall be:
      """
      {
        "project": [
          {
            "author": "John Doe",
            "email": "john.doe@example.com",
            "name": "My Project",
            "version": "1.0.0"
          },
          {
            "author": "John Doe 2",
            "email": "john.doe2@example.com",
            "name": "My Project 2",
            "version": "2.0.0"
          }
        ],
        "stack": [
          "mongodb",
          "express",
          "react",
          "node"
        ]
      }
      """

  Scenario: You cannot navigate out of the root directory using a !reference-all tag with a symlink.
    Given I provide input YAML:
      """
      ext: !reference-all {glob: local-external/*.yaml}
      """
    And the input YAML is in a directory "root"
    And I create a file "external/secret.yaml" with content:
      """
      secret: password123
      """
    And I create a file "external/other-secret.yaml" with content:
      """
      secret: password456
      """
    And I create a symlink "root/local-external" pointing to "external"
    And I run yaml-reference-cli
    Then the return code shall be 1

  Scenario: You cannot navigate out of the root directory using a !reference-all tag to navigate through a symlink.
    Given I provide input YAML:
      """
      links: !reference-all {glob: symlinked/*/info.yaml}
      """
    And the input YAML is in a directory "root"
    And I create a file "not-allowed/info.yaml" with content:
      """
      secret: password123
      """
    And I create a file "libs/info.yaml" with content:
      """
      lib.info: "0.1.0"
      """
    And I create a file "headers/info.yaml" with content:
      """
      header.info: "1.0.0"
      """
    And I create a symlink "root/symlinked/libs" pointing to "libs"
    And I create a symlink "root/symlinked/headers" pointing to "headers"
    And I create a symlink "root/symlinked/not-allowed" pointing to "not-allowed"
    And I explicitly allow the path "libs" to be resolved
    And I explicitly allow the path "headers" to be resolved
    And I run yaml-reference-cli
    Then the return code shall be 1
