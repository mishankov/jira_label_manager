import os, parseopt, strformat, base64, uri, json

import toml_serialization, puppy

type
  ConfigActions* = object
    jql*: string
    removeLabels*: Option[seq[string]]
    addLabels*: Option[seq[string]]

  Config* = object
    baseUrl*: string
    authConfigPath*: string
    actions*: seq[ConfigActions]

  AuthConfig* = object
    login*: string
    password*: string
    
  CliArgs* = object
    configFilePath*: string
    requestedHelp*: bool

  JiraTask* = object
    key*: string
    summary*: string


proc loadConfig*(filePath: string): Config =
  return Toml.loadFile(filePath, Config)

proc loadAuthConfig*(filePath: string): AuthConfig =
  return Toml.loadFile(filePath, AuthConfig)

proc parseCliArgs*(rawArgs: seq[string]): CliArgs =
  var args = CliArgs()

  for param in rawArgs:
    var parser = initOptParser(param)
    
    for kind, key, val in parser.getopt():
      case kind
      of cmdEnd: break
      of cmdShortOption:
          if key == "h": args.requestedHelp = true
      of cmdLongOption:
          if key == "help": args.requestedHelp = true
      of cmdArgument: args.configFilePath = key

  if not args.requestedHelp: 
    if args.configFilePath.len() == 0: args.configFilePath = "config.toml"
  
  return args

proc basicAuthHeader*(login: string, password: string): string = 
  let strToEncode = login & ":" & password;
  return fmt"Basic {encode(strToEncode)}"

proc getJiraTasks*(jql: string, config: Config, action: ConfigActions): seq[JiraTask] =
  let 
    authConfig = loadAuthConfig(config.authConfigPath)
    response = get(
      config.baseUrl & "/rest/api/latest/search?" & encodeQuery({"jql": action.jql}, false),
      headers = @[("Content-Type", "application/json"), ("Authorization", basicAuthHeader(authConfig.login, authConfig.password))]
    )

  let payloadJson = parseJson(response.body)
  echo "Tasks for jql \"", action.jql, "\":"
  for issue in payloadJson["issues"]: 
    echo issue["key"].getStr(), " - ", issue["fields"]["summary"].getStr()
    result.add(JiraTask(key: issue["key"].getStr(), summary: issue["fields"]["summary"].getStr())) 

  return result

proc removeLabelFromTask*(taskKey: string, label: string, config: Config) =
  let 
    authConfig = loadAuthConfig(config.authConfigPath)
    body = %*{"update": {"labels": [{"remove": label}]}}
    _ = put(
      config.baseUrl & "/rest/api/latest/issue/" & taskKey,
      headers = @[("Content-Type", "application/json"), ("Authorization", basicAuthHeader(authConfig.login, authConfig.password))],
      body = $body
    )

  echo fmt"Removed label {label} from {taskKey}"

proc addLabelToTask*(taskKey: string, label: string, config: Config) =
  let 
    authConfig = loadAuthConfig(config.authConfigPath)
    body = %*{"update": {"labels": [{"add": label}]}}
    _ = put(
      config.baseUrl & "/rest/api/latest/issue/" & taskKey,
      headers = @[("Content-Type", "application/json"), ("Authorization", basicAuthHeader(authConfig.login, authConfig.password))],
      body = $body
    )

  echo fmt"Added label {label} to {taskKey}"


when isMainModule:
  let cliArgs = parseCliArgs(commandLineParams())

  if cliArgs.requestedHelp:
    echo "Jira Label Manager CLI"
    echo "<ARGUMENT>:   path to config file"
    echo "--help, -h:   prints this message"
  else:
    let config = loadConfig(cliArgs.configFilePath)

    for action in config.actions:
      if action.removeLabels.isSome() or action.addLabels.isSome():
        let jiraTasks = getJiraTasks(action.jql, config, action)

        for jiraTask in jiraTasks:
          if action.removeLabels.isSome():
            for labelToRemove in action.removeLabels.get():
              removeLabelFromTask(jiraTask.key, labelToRemove, config)

          if action.addLabels.isSome():
            for labelToAdd in action.addLabels.get():
              addLabelToTask(jiraTask.key, labelToAdd, config)
