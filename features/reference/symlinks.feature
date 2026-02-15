Feature: !reference tag supports navigating through symlinks

  Scenario: Compiling a reference to a symlinked file
    Given I provide input YAML:
      """
      my-data: !reference {path: deep/file.yaml}
      """
    And I create a file "really/really/really/deep/file.yaml" with content:
      """
      __metadata__: !reference {path: metadata.yaml}
      key-1: "one"
      key-2: "two"
      """
    And I create a file "really/really/really/deep/metadata.yaml" with content:
      """
      version: "0.0.1"
      """
    And I create a symlink "deep" pointing to "really/really/really/deep"
    And I run yaml-reference-cli
    Then the output shall be:
      """
      {
        "my-data": {
          "__metadata__": {
            "version": "0.0.1"
          },
          "key-1": "one",
          "key-2": "two"
        }
      }
      """
