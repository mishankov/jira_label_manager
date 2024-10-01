package main

import (
	"errors"
	"fmt"
	"os"
	"strings"
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

		configFileName, err := userInput(`Config path (default is "config.toml"): `)
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

		jira := Jira{baseUrl: config.BaseUrl, login: authConfig.Login, password: authConfig.Password}

		for {
			fmt.Print()
			jql, err := userInput("Input JQL: ")
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
			labelsToRemove, err := userInput("Input comma-separated lables to remove form tasks: ")
			if err != nil {
				fmt.Println("Error:", err.Error())
				os.Exit(1)
			}
			labelsToRemoveList := strings.Split(labelsToRemove, ",")

			fmt.Print()
			labelsToAdd, err := userInput("Input comma-separated lables to add to tasks: ")
			if err != nil {
				fmt.Println("Error:", err.Error())
				os.Exit(1)
			}
			labelsToAddList := strings.Split(labelsToAdd, ",")

			for _, task := range tasks {
				for _, label := range labelsToRemoveList {
					label := strings.TrimSpace(label)
					if len(label) > 0 {
						fmt.Println("Removing label", label, "for task", task.key)
						jira.labelAction(task.key, JiraTaskAction{isRemove: true}, label)
					}
				}

				for _, label := range labelsToAddList {
					label := strings.TrimSpace(label)
					if len(label) > 0 {
						fmt.Println("Adding label", label, "for task", task.key)
						jira.labelAction(task.key, JiraTaskAction{isAdd: true}, label)
					}
				}
			}

			fmt.Print()
			answer, err := userInput("Continue? (y/n): ")
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

		jira := Jira{baseUrl: config.BaseUrl, login: authConfig.Login, password: authConfig.Password}

		for _, action := range config.Actions {
			if len(action.RemoveLabels) > 0 || len(action.AddLabels) > 0 {
				tasks, err := jira.getJiraTasksByJQL(action.Jql)

				if err != nil {
					fmt.Println("Error:", err.Error())
					os.Exit(1)
				}

				for _, task := range tasks {
					if len(action.RemoveLabels) > 0 {
						for _, label := range action.RemoveLabels {
							fmt.Println("Removing label", label, "for task", task.key)
							err := jira.labelAction(task.key, JiraTaskAction{isRemove: true}, label)

							if err != nil {
								fmt.Println("Error:", err.Error())
							}
						}
					}

					if len(action.AddLabels) > 0 {
						for _, label := range action.AddLabels {
							fmt.Println("Adding label", label, "for task", task.key)
							err := jira.labelAction(task.key, JiraTaskAction{isAdd: true}, label)

							if err != nil {
								fmt.Println("Error:", err.Error())
							}
						}
					}
				}
			}
		}
	}
}
