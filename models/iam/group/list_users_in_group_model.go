package group

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	view "github.com/DragonEmperor9480/aws_cli_manager/views/iam/group"
)

func ListUsersInGroupModel(groupname string) {
	cmd := exec.Command("aws", "iam", "get-group", "--group-name", groupname, "--query", "Users[*].UserName", "--output", "text")
	outputBytes, err := cmd.CombinedOutput()
	output := string(outputBytes)

	if strings.Contains(output, "NoSuchEntity") {
		fmt.Println(utils.Bold + utils.Red + "Group '" + groupname + "' does not exist!" + utils.Reset)
		return
	}

	if err != nil || strings.TrimSpace(output) == "" {
		fmt.Println(utils.Bold + utils.Yellow + "No users found in group '" + groupname + "'." + utils.Reset)
		return
	}

	users := strings.Fields(output)
	view.ShowGroupUsersTable(groupname, users)
}
