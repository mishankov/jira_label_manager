package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func userInput(promt string) (string, error) {
	if len(promt) > 0 {
		fmt.Print(promt)
	}

	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(input), err

}
