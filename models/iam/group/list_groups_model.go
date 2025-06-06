package group

import (
	"os/exec"
	"strings"
)

func FetchIAMGroups() (string, error) {
	cmd := exec.Command("aws", "iam", "list-groups", "--query", "Groups[*].[GroupName, GroupId, CreateDate]", "--output", "text")
	outputBytes, err := cmd.CombinedOutput()
	return string(outputBytes), err
}

func FetchOnlyGroupNames() []string {
	cmd := exec.Command("aws", "iam", "list-groups", "--query", "Groups[*].GroupName", "--output", "text")
	outputBytes, _ := cmd.CombinedOutput()
	output := string(outputBytes)
	return strings.Fields(output)
}
