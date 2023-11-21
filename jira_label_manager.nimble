import strformat

# Package

version       = "0.2.0"
author        = "Denis Mishankov"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
binDir        = "build"
bin           = @["jira_label_manager"]


# Dependencies

requires "nim >= 2.0.0", "toml_serialization >= 0.2.6", "yahttp >= 0.2.1"


task devc, "Dev config":
    exec "nimble run --cpu:amd64 -d:ssl jira_label_manager config.toml"

task devi, "Dev interactive":
    exec "nimble run --cpu:amd64 -d:ssl jira_label_manager"

task test_help, "Test help":
    exec "build/jira_label_manager.exe --help"

task release, "Release":
    exec fmt"nimble c --cpu:amd64 -d:ssl -d:release -f:on -o:build/jira_label_manager_{version}.exe src/jira_label_manager -y"
