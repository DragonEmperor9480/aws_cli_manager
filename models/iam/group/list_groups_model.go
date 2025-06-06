package group

import (
	"os/exec"
)

func FetchIAMGroups() (string, error) {
	cmd := exec.Command("aws", "iam", "list-groups", "--query", "Groups[*].[GroupName, GroupId, CreateDate]", "--output", "text")
	outputBytes, err := cmd.CombinedOutput()
	return string(outputBytes), err
}
