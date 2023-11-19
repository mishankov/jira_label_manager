import os, parseopt, options

import config, jira

type
  CliArgs* = object
    configFilePath*: string
    requestedHelp*: bool


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


when isMainModule:
  let cliArgs = parseCliArgs(commandLineParams())

  if cliArgs.requestedHelp:
    echo "Jira Label Manager CLI"
    echo "<ARGUMENT>:   path to config file"
    echo "--help, -h:   prints this message"
  else:
    let config = loadConfig(cliArgs.configFilePath)
    let authConfig = loadAuthConfig(config.authConfigPath)
    let jira = Jira(
      baseUrl: config.baseUrl, 
      login: authConfig.login, 
      password: authConfig.password, 
      ignoreSsl: config.ignoreSsl.get(false)
    )

    for action in config.actions:
      if action.removeLabels.isSome() or action.addLabels.isSome():
        let jiraTasks = jira.getJiraTasks(action.jql)

        for jiraTask in jiraTasks:
          if action.removeLabels.isSome():
            for labelToRemove in action.removeLabels.get():
              jira.labelAction(jiraTask.key, remove, labelToRemove)

          if action.addLabels.isSome():
            for labelToAdd in action.addLabels.get():
              jira.labelAction(jiraTask.key, add, labelToAdd)
