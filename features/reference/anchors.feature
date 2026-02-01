Feature: !reference tag shall support anchor references

    Scenario: Simple cross-file anchor reference with !reference
        Given I create a file "data.yml" with content:
            """
            firstName: &f John
            lastName: &l Doe
            age: 30
            """
        And I provide input YAML:
            """
            names:
            - !reference {path: data.yml, anchor: f}
            - !reference {path: data.yml, anchor: l}
            """
        When I run yref-compile with any I/O mode
        Then the output shall be:
            """
            names:
            - John
            - Doe
            """

    Scenario: Cross-file anchor reference with !reference in nested structure
        Given I create a file "src-anchored.yml" with content:
            """
            uuids:
              v4: &id 123e4567-e89b-12d3-a456-426614174000
            
            metadata:
              items: [a, b, c]
            """
        And I create a file "src-uuid-v4-2.yml" with content:
            """
            123e4567-e89b-12d3-a456-426614174001
            """
        And I create a file "intermediate.yml" with content:
            """
            idV4: !reference &id {path: src-anchored.yml, anchor: id}
            altIdV4: &alt !reference {path: src-uuid-v4-2.yml}
            """
        And I provide input YAML:
            """
            record:
              primaryId: !reference {path: intermediate.yml, anchor: id}
              secondaryId: !reference {path: intermediate.yml, anchor: alt}
            """
        When I run yref-compile with any I/O mode
        Then the output shall be:
            """
            record:
              primaryId: 123e4567-e89b-12d3-a456-426614174000
              secondaryId: 123e4567-e89b-12d3-a456-426614174001
            """
