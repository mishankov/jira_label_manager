import os, parseopt

import toml_serialization

type
  ConfigActions* = object
    jql*: string
    removeLabels*: Option[seq[string]]
    addLabels*: Option[seq[string]]

  Config* = object
    baseUrl*: string
    login*: string
    password*: string
    actions*: seq[ConfigActions]

  CliArgs* = object
    configFilePath*: string
    requestedHelp*: bool

  JiraTask* = object
    key*: string
    summary*: string


proc loadConfig*(filePath: string): Config =
  return Toml.loadFile(filePath, Config)

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

proc getJiraTasks*(jql: string): seq[JiraTask] =
  echo "getJiraTasks"
  return @[JiraTask()]

proc removeLabelFromTask*(taskKey: string, label: string) =
  echo "removeLabelFromTask"

proc addLabelToTask*(taskKey: string, label: string) =
  echo "addLabelToTask" 


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
        let jiraTasks = getJiraTasks(action.jql)

        for jiraTask in jiraTasks:
          if action.removeLabels.isSome():
            for labelToRemove in action.removeLabels.get():
              removeLabelFromTask(jiraTask.key, labelToRemove)

          if action.addLabels.isSome():
            for labelToAdd in action.addLabels.get():
              addLabelToTask(jiraTask.key, labelToAdd)
