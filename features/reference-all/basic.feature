Feature: !reference-all tag basically functions

  Scenario: Compiling a file with !reference-all pointing to a single file shall behave like !reference but wrap theresult in an array.
    Given I provide input YAML:
      """
      allData: !reference-all {glob: data.yml}
      """
    And I create a file "data.yml" with content:
      """
      keyA: valueA
      keyB:
      - listItem1
      - listItem2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "allData": [
          {
            "keyA": "valueA",
            "keyB": [
              "listItem1",
              "listItem2"
            ]
          }
        ]
      }
      """

  Scenario: Compiling a file with !reference-all pointing to multiple files shall gather all referenced contents into an array.
    Given I provide input YAML:
      """
      allData: !reference-all {glob: data-*.yml}
      """
    And I create a file "data-1.yml" with content:
      """
      key: value1
      """
    And I create a file "data-2.yml" with content:
      """
      key: value2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "allData": [
          {
            "key": "value1"
          },
          {
            "key": "value2"
          }
        ]
      }
      """

  Scenario: Compiling a file with !reference-all pointing to multiple files in a subdirectory shall gather all referenced contents into an array.
    Given I provide input YAML:
      """
      configurations: !reference-all {glob: configs/*.yml}
      """
    And I create a file "configs/db.yml" with content:
      """
      db:
        region: us-east-1
        shards: 3
      """
    And I create a file "configs/client.yml" with content:
      """
      client:
        image: client-app:latest
        replicas: 5
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "configurations": [
          {
            "client": {
              "image": "client-app:latest",
              "replicas": 5
            }
          },
          {
            "db": {
              "region": "us-east-1",
              "shards": 3
            }
          }
        ]
      }
      """

  Scenario: Compiling a file with !reference-all on an anchored node shall preserve the anchor.
    Given I provide input YAML:
      """
      items: &it
        !reference-all {glob: names/*.yml}
      itemsAgain: *it
      """
    And I create a file "names/1.yml" with content:
      """
      One
      ...
      """
    And I create a file "names/2.yml" with content:
      """
      Two
      ...
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "items": [
          "One",
          "Two"
        ],
        "itemsAgain": [
          "One",
          "Two"
        ]
      }
      """

  Scenario: Files matched by !reference-all are ordered alphabetically by filename
    Given I create a file "child/z.yaml" with content:
      """
      val: Zulu
      """
    And I create a file "child/a.yaml" with content:
      """
      val: Alpha
      """
    And I create a file "child/m.yaml" with content:
      """
      val: Mike
      """
    And I provide input YAML:
      """
      results: !reference-all {glob: "child/*.yaml"}
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "results": [
          {
            "val": "Alpha"
          },
          {
            "val": "Mike"
          },
          {
            "val": "Zulu"
          }
        ]
      }
      """

  Scenario: Multi-level glob matches in !reference-all are sorted alphabetically by path in JSON output
    Given I create a file "child/aa/r/dvark.yaml" with content:
      """
      id: dvark
      """
    And I create a file "child/apps/z.yaml" with content:
      """
      id: zulu
      """
    And I create a file "child/libs/a.yaml" with content:
      """
      id: alpha
      """
    And I create a file "child/libs/m.yaml" with content:
      """
      id: mike
      """
    And I provide input YAML:
      """
      items: !reference-all {glob: "child/**/*.yaml"}
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "items": [
          {
            "id": "dvark"
          },
          {
            "id": "zulu"
          },
          {
            "id": "alpha"
          },
          {
            "id": "mike"
          }
        ]
      }
      """

  Scenario: Shorthand string scalar is equivalent to providing a glob argument

    Given I provide input YAML:
      """
      allData: !reference-all "data-*.yml"
      """
    And I create a file "data-1.yml" with content:
      """
      key: value1
      """
    And I create a file "data-2.yml" with content:
      """
      key: value2
      """
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "allData": [
          {
            "key": "value1"
          },
          {
            "key": "value2"
          }
        ]
      }
      """

  Scenario: Compiling a file with !reference-all when no files match the glob shall produce an empty array.
    Given I provide input YAML:
      """
      items: !reference-all {glob: nonexistent-*.yml}
      """
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      {
        "items": []
      }
      """

  Scenario: An anchored mapping with a glob pattern can be aliased as an argument to a !reference-all tag.
    Given I create a file "api/models/crm/account.yaml" with content:
      """
      name: Account
      type: object
      """
    And I create a file "api/models/crm/txn/sale.yaml" with content:
      """
      name: Sale
      type: object
      """
    And I provide input YAML:
      """
      references:
        - &models 'api/models/**/*.yaml'
      items: !reference-all {glob: *models}
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "items": [
          {
            "name": "Account",
            "type": "object"
          },
          {
            "name": "Sale",
            "type": "object"
          }
        ],
        "references": [
          "api/models/**/*.yaml"
        ]
      }
      """

  Scenario: Compiling a file with !reference-all pointing to a single multi-document YAML file shall chain all documents into the result array.
    Given I provide input YAML:
      """
      References: !reference-all {glob: "docs.yaml"}
      """
    And I create a file "docs.yaml" with content:
      """
      Hello: World
      ---
      Goodbye: World
      ---
      - Apple
      - Orange
      """
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      {
        "References": [
          {
            "Hello": "World"
          },
          {
            "Goodbye": "World"
          },
          [
            "Apple",
            "Orange"
          ]
        ]
      }
      """

  Scenario: Compiling a file with !reference-all where a glob matches a mix of single- and multi-document YAML files shall chain all documents into the result array.
    Given I provide input YAML:
      """
      items: !reference-all {glob: "data-*.yaml"}
      """
    And I create a file "data-single.yaml" with content:
      """
      key: single
      """
    And I create a file "data-multi.yaml" with content:
      """
      key: first
      ---
      key: second
      """
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      {
        "items": [
          {
            "key": "first"
          },
          {
            "key": "second"
          },
          {
            "key": "single"
          }
        ]
      }
      """

  Scenario: Compiling a file with !reference-all where the target multi-document file contains !ignored documents shall exclude those documents from the result.
    Given I provide input YAML:
      """
      Content: !merge
        - !reference-all docs.yaml
      """
    And I create a file "docs.yaml" with content:
      """
      !ignore |-
      This is my header for the document.
      It will be suppressed from the result of the !reference-all tag.
      ---
      Doc: Name of my document
      Version: 1.0
      Authors:
       - Ralph
       - Philip
       - Victoria
       - Zoey
      ---
      !ignore |-
      This is my footer for the document.
      It will be suppressed from the result of the !reference-all tag.

      Last edited: 2026-03-16
      """
    And I run yaml-reference-cli
    Then the return code shall be 0
    And the output shall be:
      """
      {
        "Content": {
          "Authors": [
            "Ralph",
            "Philip",
            "Victoria",
            "Zoey"
          ],
          "Doc": "Name of my document",
          "Version": "1.0"
        }
      }
      """
