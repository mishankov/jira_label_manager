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

  CLIArgs* = object
    configFilePath*: string
    requestedHelp*: bool


proc loadConfig*(filePath: string): Config =
  return Toml.loadFile(filePath, Config)

proc parseCliArgs(): CLIArgs =
  var args = CLIArgs()

  for param in commandLineParams():
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
  let cliArgs = parseCliArgs()

  if cliArgs.requestedHelp:
    echo "Jira Label Manager CLI"
    echo "<ARGUMENT>:   path to config file"
    echo "--help, -h:   prints this message"
  else:
    echo loadConfig(cliArgs.configFilePath)
