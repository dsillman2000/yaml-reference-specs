Feature: !reference-all should sometimes throw errors.

  Scenario: Compiling a file with !reference-all when no files match the glob shall raise an error.
    Given I provide input YAML:
      """
      items: !reference-all {glob: nonexistent-*.yml}
      """
    And I run yref-compile with any I/O mode
    Then the return code shall be 1

  Scenario: Compiling a file with !reference-all on a scalar node shall raise an error.
    Given I provide input YAML:
      """
      items: !reference-all glob: all/my/*.yml
      """
    And I create a file "all/my/1.yml" with content:
      """
      even: if
      """
    And I create a file "all/my/2.yml" with content:
      """
      these: exist
      """
    And I run yref-compile with any I/O mode
    Then the return code shall be 1
