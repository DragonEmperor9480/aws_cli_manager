package group

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func RemoveUserFromGroupModel(username, groupname string) {
	utils.ShowProcessingAnimation("Removing user '" + username + "' from group '" + groupname + "'")
	cmd := exec.Command("aws", "iam", "remove-user-from-group", "--group-name", groupname, "--user-name", username)
	outputBytes, _ := cmd.CombinedOutput()
	output := string(outputBytes)
	utils.StopAnimation()

	if strings.TrimSpace(output) == "" {
		fmt.Println(utils.Bold + utils.Green + "User '" + username + "' removed to group '" + groupname + "' successfully!" + utils.Reset)

	} else if strings.Contains(output, "NoSuchEntity") {
		fmt.Println(utils.Bold + utils.Red + "Error: Either the User or Group does not exist!" + utils.Reset)
	} else {
		fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
		fmt.Println(output)
	}
}
