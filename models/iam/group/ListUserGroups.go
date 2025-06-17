package group

import (
	"os/exec"
	"strings"

)

func ListUserGroupsModel(username string) []string {
	cmd := exec.Command("aws", "iam", "list-groups-for-user", "--user-name", username, "--query", "Groups[*].GroupName", "--output", "text")
	outputBytes, _ := cmd.Output()
	output := string(outputBytes)

	// Split the space-separated group names into a slice
	groupNames := strings.Fields(output)
	return groupNames
}