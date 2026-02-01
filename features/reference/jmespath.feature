Feature: !reference tag supports jmespath transformations on referenced files

    Scenario: Apply jmespath expression to referenced file content
        Given I create a file "data.yml" with content:
            """
            users:
            - name: Alice
              age: 30
            - name: Bob
              age: 25
            - name: Charlie
              age: 35
            """
        And I provide input YAML:
            """
            oldestUser: !reference
              path: data.yml
              jmespath: "users | sort_by(@, &age) | [-1]"
            """
        When I run yref-compile with any I/O mode
        Then the output shall be:
            """
            oldestUser:
              name: Charlie
              age: 35
            """

    Scenario: Extract specific fields using jmespath from referenced file
        Given I create a file "config.yml" with content:
            """
            database:
              host: db.example.com
              port: 5432
              username: admin
              password: secret
            """
        And I provide input YAML:
            """
            dbHost: !reference {path: config.yml, jmespath: "database.host"}
            dbPort: !reference {path: config.yml, jmespath: "database.port"}
            """
        When I run yref-compile with any I/O mode
        Then the output shall be:
            """
            dbHost: db.example.com
            dbPort: 5432
            """

    Scenario: Use jmespath to filter a list from referenced file
        Given I create a file "items.yml" with content:
            """
            items:
            - id: 1
              category: A
            - id: 2
              category: B
            - id: 3
              category: A
            - id: 4
              category: C
            """
        And I provide input YAML:
            """
            categoryAItems: !reference
              path: items.yml
              jmespath: "items[?category=='A']"
            """
        When I run yref-compile with any I/O mode
        Then the output shall be:
            """
            categoryAItems:
            - id: 1
              category: A
            - id: 3
              category: A
            """