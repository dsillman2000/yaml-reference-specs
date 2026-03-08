Feature: !ignore tag interacts cleanly with other dynamic tags.

  Scenario: !reference to a file with an !ignore root evaluates to null.
    Given I create a file "ignored_file.yaml" with content:
      """
      !ignore
      secret_data: 123
      """
    And I provide input YAML:
      """
      data: !reference ignored_file.yaml
      """
    And I explicitly allow the path "ignored_file.yaml" to be resolved
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "data": null
      }
      """

  Scenario: !reference-all to ignored files leaves null in the generated array.
    Given I create a file "secrets/public.yaml" with content:
      """
      public: true
      """
    And I create a file "secrets/secret1.yaml" with content:
      """
      !ignore
      data: 1
      """
    And I provide input YAML:
      """
      items: !reference-all secrets/*.yaml
      """
    And I explicitly allow the path "secrets/" to be resolved
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "items": [
          {
            "public": true
          },
          null
        ]
      }
      """
