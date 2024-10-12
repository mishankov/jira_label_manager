package main

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/mishankov/go-utlz/cliutils"
)

type CLArgs struct {
	isHelp         bool
	isInteractive  bool
	isConfigFile   bool
	configFileName string
}

func parseCLArgs() (CLArgs, error) {
	switch len(os.Args) {
	case 1:
		return CLArgs{isInteractive: true}, nil
	case 2:
		switch argument := os.Args[1]; {
		case argument == "--help", argument == "-h":
			return CLArgs{isHelp: true}, nil
		default:
			return CLArgs{isConfigFile: true, configFileName: argument}, nil
		}
	default:
		return CLArgs{}, errors.New("invalid number of arguments. Run jira_label_manager --help to get help")
	}
}

func main() {
	clArgs, err := parseCLArgs()

	if err != nil {
		fmt.Println("Error:", err.Error())
		os.Exit(1)
	}

	switch {
	case clArgs.isHelp:
		fmt.Println("Jira Label Manager CLI")
		fmt.Println("<ARGUMENT>:   path to config file")
		fmt.Println("--help, -h:   prints this message")
	case clArgs.isInteractive:
		fmt.Println("Launching in interactive mode")

		configFileName, err := cliutils.UserInput(`Config path (default is "config.toml"): `)
		if err != nil {
			fmt.Println("Error:", err.Error())
			os.Exit(1)
		}

		if len(configFileName) == 0 {
			configFileName = "config.toml"
		}

		config, err := loadConfig(configFileName)
		if err != nil {
			fmt.Println("Error:", err.Error())
			os.Exit(1)
		}

		authConfig, err := loadAuthConfig(config.AuthConfigPath)
		if err != nil {
			fmt.Println("Error:", err.Error())
			os.Exit(1)
		}

		jira := Jira{baseUrl: config.BaseUrl, login: authConfig.Login, password: authConfig.Password, ignoreSsl: config.IgnoreSsl}

		for {
			fmt.Print()
			jql, err := cliutils.UserInput("Input JQL: ")
			if err != nil {
				fmt.Println("Error:", err.Error())
				os.Exit(1)
			}

			if len(jql) == 0 {
				fmt.Println("No JQL entered. Try again")
				continue
			}

			tasks, err := jira.getJiraTasksByJQL(jql)
			if err != nil {
				fmt.Println("Error:", err.Error())
				os.Exit(1)
			}

			fmt.Println("Tasks:")
			for _, task := range tasks {
				fmt.Println(task)
			}

			fmt.Print()
			labelsToRemove, err := cliutils.UserInput("Input comma-separated lables to remove form tasks: ")
			if err != nil {
				fmt.Println("Error:", err.Error())
				os.Exit(1)
			}
			labelsToRemoveList := strings.Split(labelsToRemove, ",")

			fmt.Print()
			labelsToAdd, err := cliutils.UserInput("Input comma-separated lables to add to tasks: ")
			if err != nil {
				fmt.Println("Error:", err.Error())
				os.Exit(1)
			}
			labelsToAddList := strings.Split(labelsToAdd, ",")

			jira.applyLabelChanges(tasks, labelsToRemoveList, labelsToAddList)

			fmt.Print()
			answer, err := cliutils.UserInput("Continue? (y/n): ")
			if err != nil {
				fmt.Println("Error:", err.Error())
				os.Exit(1)
			}

			if answer != "y" {
				fmt.Println("Ciao!")
				break
			}
		}

	case clArgs.isConfigFile:
		fmt.Println("Loading config file:", clArgs.configFileName)
		config, err := loadConfig(clArgs.configFileName)

		if err != nil {
			fmt.Println("Error:", err.Error())
			os.Exit(1)
		}

		authConfig, err := loadAuthConfig(config.AuthConfigPath)

		if err != nil {
			fmt.Println("Error:", err.Error())
			os.Exit(1)
		}

		jira := Jira{baseUrl: config.BaseUrl, login: authConfig.Login, password: authConfig.Password, ignoreSsl: config.IgnoreSsl}

		for _, action := range config.Actions {
			if len(action.RemoveLabels) > 0 || len(action.AddLabels) > 0 {
				tasks, err := jira.getJiraTasksByJQL(action.Jql)

				if err != nil {
					fmt.Println("Error:", err.Error())
					os.Exit(1)
				}

				jira.applyLabelChanges(tasks, action.RemoveLabels, action.AddLabels)
			}
		}
	}
}
