import toml_serialization

type
  ConfigActions* = object
    keys*: seq[string]
    getActualKey*: bool
    jql*: string
    removeLabels*: seq[string]
    addLabels*: seq[string]


  Config* = object
    baseUrl*: string
    login*: string
    password*: string
    actions*: seq[ConfigActions]


proc loadConfig*(filePath: string): Config =
  return Toml.loadFile(filePath, Config)


when isMainModule:
  echo loadConfig("config.example.toml")
