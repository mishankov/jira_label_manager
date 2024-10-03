package main

import (
	"os"

	"github.com/BurntSushi/toml"
)

type ConfigActions struct {
	Jql          string
	RemoveLabels []string
	AddLabels    []string
}

type Config struct {
	BaseUrl        string
	AuthConfigPath string
	IgnoreSsl      bool
	Actions        []ConfigActions
}

type AuthConfig struct {
	Login    string
	Password string
}

func loadConfig(path string) (Config, error) {
	data, err := os.ReadFile(path)

	if err != nil {
		return Config{}, err
	}

	var config Config
	_, errDecode := toml.Decode(string(data), &config)

	if errDecode != nil {
		return Config{}, errDecode
	}

	return config, nil
}

func loadAuthConfig(path string) (AuthConfig, error) {
	data, err := os.ReadFile(path)

	if err != nil {
		return AuthConfig{}, err
	}

	var config AuthConfig
	_, errDecode := toml.Decode(string(data), &config)

	if errDecode != nil {
		return AuthConfig{}, errDecode
	}

	return config, nil
}
