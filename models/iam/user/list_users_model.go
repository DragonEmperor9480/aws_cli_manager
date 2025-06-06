package user

import (
	"os/exec"
	"strings"
)

func FetchIAMUsers() (string, error) {
	cmd := exec.Command("aws", "iam", "list-users", "--query", "Users[*].[UserName,UserId,CreateDate]", "--output", "text")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func FetchOnlyUsernames() []string {
	cmd := exec.Command("aws", "iam", "list-users", "--query", "Users[*].UserName", "--output", "text")
	outputBytes, _ := cmd.CombinedOutput()
	output := string(outputBytes)

	// Split by space (text output returns space-separated usernames)
	usernames := strings.Fields(output)
	return usernames
}