import toml_serialization

type
  ConfigActions* = object
    jql*: string
    removeLabels*: Option[seq[string]]
    addLabels*: Option[seq[string]]

  Config* = object
    baseUrl*: string
    authConfigPath*: string
    ignoreSsl*: Option[bool]
    actions*: seq[ConfigActions]

  AuthConfig* = object
    login*: string
    password*: string

proc loadConfig*(filePath: string): Config =
  return Toml.loadFile(filePath, Config)

proc loadAuthConfig*(filePath: string): AuthConfig =
  return Toml.loadFile(filePath, AuthConfig)
