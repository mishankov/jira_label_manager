# Package

version       = "0.1.0"
author        = "Denis Mishankov"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
binDir        = "build"
bin           = @["jira_label_manager"]


# Dependencies

requires "nim >= 2.0.0", "toml_serialization >= 0.2.6"


task dev, "Dev":
    exec "nimble run --cpu:amd64 jira_label_manager config.toml"

task test_help, "Test help":
    exec "nimble c --cpu:amd64 -o:build/jira_label_manager_release src/jira_label_manager"
    exec "build/jira_label_manager.exe --help"