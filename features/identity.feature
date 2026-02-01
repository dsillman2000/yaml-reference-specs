Feature: yref-compile does not modify target files not containing any !reference tags

    Scenario: Compiling a file without !reference tags leaves it unchanged
        Given I provide input YAML:
            """
            key1: value1
            key2:
            - item1
            - item2
            """
        And I run yref-compile with any I/O mode
        Then the output shall be:
            """
            key1: value1
            key2:
            - item1
            - item2
            """
