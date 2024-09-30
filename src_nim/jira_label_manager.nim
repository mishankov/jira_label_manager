import os, parseopt, options, strutils

import config, jira

type
  AppMode = enum Config, Interactive, Help

  CliArgs = object
    configFilePath: string
    mode: AppMode


proc parseCliArgs(rawArgs: seq[string]): CliArgs =
  var args = CliArgs()

  for param in rawArgs:
    var parser = initOptParser(param)
    
    for kind, key, val in parser.getopt():
      case kind
      of cmdEnd: break
      of cmdShortOption:
          if key == "h": args.mode = AppMode.Help
          return args
      of cmdLongOption:
          if key == "help": args.mode = AppMode.Help
          return args
      of cmdArgument: args.configFilePath = key

  if args.configFilePath.len() == 0: 
    args.mode = AppMode.Interactive
  else:
    args.mode = AppMode.Config
  
  return args


when isMainModule:
  let cliArgs = parseCliArgs(commandLineParams())

  case cliArgs.mode:
  of Help:
    echo "Jira Label Manager CLI"
    echo "<ARGUMENT>:   path to config file"
    echo "--help, -h:   prints this message"
  of Config:
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
  of Interactive:
    write(stdout, "Config path (default is \"config.toml\"): ")
    var input = readLine(stdin)
    var configFilePath = if input.len() > 0: input else: "config.toml"
    let config = loadConfig(configFilePath)
    let authConfig = loadAuthConfig(config.authConfigPath)

    let jira = Jira(
      baseUrl: config.baseUrl, 
      login: authConfig.login, 
      password: authConfig.password, 
      ignoreSsl: config.ignoreSsl.get(false)
    )

    while true:
      write(stdout, "Input JQL: ")
      let jql = readLine(stdin)
      if jql.len() == 0: 
        echo "No JQL entered. Try again"
        continue

      let jiraTasks = jira.getJiraTasks(jql)

      write(stdout, "Input comma-separated lables to remove form tasks: ")
      let labelsToRemove = readLine(stdin).split(",")

      write(stdout, "Input comma-separated lables to add to tasks: ")
      let labelsToAdd = readLine(stdin).split(",")

      for task in jiraTasks:
        if labelsToRemove.len() > 0 and labelsToRemove[0].len() > 0:
          for label in labelsToRemove:
            jira.labelAction(task.key, remove, label)

        if labelsToAdd.len() > 0 and labelsToAdd[0].len() > 0:
          for label in labelsToAdd:
            jira.labelAction(task.key, add, label)

      write(stdout, "Continue? (y/n):  ")
      if not (if readLine(stdin) == "y": true else: false):
        echo "Ciao!"
        break

