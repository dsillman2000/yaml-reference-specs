Feature: Nested !reference tags

    Scenario: A file references another file which references a third file
        Given I create a file "third.yaml" with content:
        """
        final: 42
        """
        And I create a file "second.yaml" with content:
        """
        value: !reference {path: third.yaml}
        """
        And I provide input YAML:
        """
        root: !reference {path: second.yaml}
        """
        When I run yref-compile with any I/O mode
        Then the output shall be:
        """
        root:
          value:
            final: 42
        """

    Scenario: A file references two other files
        Given I create a file "a.yaml" with content:
        """
        alpha: A
        """
        And I create a file "b.yaml" with content:
        """
        beta: B
        """
        And I create a file "second-multi.yaml" with content:
        """
        partA: !reference {path: a.yaml}
        partB: !reference {path: b.yaml}
        """
        And I provide input YAML:
        """
        root: !reference {path: second-multi.yaml}
        """
        When I run yref-compile with any I/O mode
        Then the output shall be:
        """
        root:
          partA:
            alpha: A
          partB:
            beta: B
        """
