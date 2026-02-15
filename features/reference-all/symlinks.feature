Feature: !reference-all tag supports navigating through symlinks

  Scenario: Compiling a reference to a symlinked file
    Given I provide input YAML:
      """
      my-data: !reference {path: deep/file.yaml}
      """
    And I create a file "really/really/really/deep/file.yaml" with content:
      """
      __metadata__: !reference {path: metadata.yaml}
      keys: !reference-all {glob: "key-*.yaml"}
      """
    And I create a file "really/really/really/deep/metadata.yaml" with content:
      """
      version: "0.0.2"
      """
    And I create a file "really/really/really/deep/key-1.yaml" with content:
      """
      key-1: "one"
      """
    And I create a file "really/really/really/deep/key-2.yaml" with content:
      """
      key-2: "two"
      """
    And I create a symlink "deep" pointing to "really/really/really/deep"
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "my-data": {
          "__metadata__": {
            "version": "0.0.2"
          },
          "keys": [
            {
              "key-1": "one"
            },
            {
              "key-2": "two"
            }
          ]
        }
      }
      """

  Scenario: Compiling a !reference-all tag to a directory containing symlinks which should be navigated
    Given I provide input YAML:
      """
      families: !reference-all {glob: "family-enlets/*/info.yaml"}
      """
    And I create a file "family/data/enlets/en-fam/info.yaml" with content:
      """
      Language: English
      EnumeratedLetters: [A, B, C]
      """
    And I create a file "family/data/enlets/gr-fam/info.yaml" with content:
      """
      Language: Greek
      EnumeratedLetters: [alpha, beta, gamma]
      """
    And I create a symlink "family-enlets" pointing to "family/data/enlets"
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "families": [
          {
            "EnumeratedLetters": [
              "A",
              "B",
              "C"
            ],
            "Language": "English"
          },
          {
            "EnumeratedLetters": [
              "alpha",
              "beta",
              "gamma"
            ],
            "Language": "Greek"
          }
        ]
      }
      """
