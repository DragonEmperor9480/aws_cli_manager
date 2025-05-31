package iam

import (
	"os/exec"
)

func FetchIAMUsers() (string, error) {
	cmd := exec.Command("aws", "iam", "list-users", "--query", "Users[*].[UserName,UserId,CreateDate]", "--output", "text")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return string(out), nil
}
