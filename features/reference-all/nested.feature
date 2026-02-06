Feature: Nested !reference-all tags

  Scenario: A file reference tree
    Given I provide input YAML:
      """
      froot: !reference-all {glob: "branches/*.yml"}
      """
    And I create a file "branches/oranges.yml" with content:
      """
      oranges: !reference-all {glob: "**/orange-*.yml"}
      """
    And I create a file "branches/north-branch/orange-matt.yml" with content:
      """
      orange: Matt
      """
    And I create a file "branches/west-branch/orange-mark.yml" with content:
      """
      orange: Mark
      """
    And I create a file "branches/west-branch/orange-philip.yml" with content:
      """
      orange: Philip
      """
    And I create a file "branches/apples.yml" with content:
      """
      apples: !reference-all {glob: "**/apple-*.yml"}
      """
    And I create a file "branches/north-branch/apple-cheryl.yml" with content:
      """
      apple: Cheryl
      """
    And I create a file "branches/north-branch/apple-debra.yml" with content:
      """
      apple: Debra
      """
    And I create a file "branches/west-branch/apple-rochelle.yml" with content:
      """
      apple: Rochelle
      """
    When I run yref-compile with any I/O mode
    Then the output shall be:
      """
      froot:
      - apples:
        - apple: Cheryl
        - apple: Debra
        - apple: Rochelle
      - oranges:
        - orange: Matt
        - orange: Mark
        - orange: Philip
      """
