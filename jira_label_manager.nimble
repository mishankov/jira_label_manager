# Package

version       = "0.1.0"
author        = "Denis Mishankov"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["jira_label_manager"]


# Dependencies

requires "nim >= 2.0.0"


task dev, "Dev":
    exec "nimble run --cpu:amd64"
