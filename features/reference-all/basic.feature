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

  Scenario: Anchored mapping nodes can be aliased as arguments to !reference-all tags.
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
      .accountModel: &account
        glob: "api/models/crm/account.yaml"
      .saleModel: &sale
        glob: "api/models/crm/txn/sale.yaml"
      items:
      - !reference-all *sale
      - !reference-all *account
      """
    When I run yaml-reference-cli
    Then the output shall be:
      """
      {
        ".accountModel": {
          "glob": "api/models/crm/account.yaml"
        },
        ".saleModel": {
          "glob": "api/models/crm/txn/sale.yaml"
        },
        "items": [
          [
            {
              "name": "Sale",
              "type": "object"
            }
          ],
          [
            {
              "name": "Account",
              "type": "object"
            }
          ]
        ]
      }
      """
