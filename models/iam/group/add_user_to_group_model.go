package group

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func AddUserToGroupModel(username, groupname string) {
	utils.ShowProcessingAnimation("Adding User to Group")
	cmd := exec.Command("aws", "iam", "add-user-to-group", "--user-name", username, "--group-name", groupname)
	outputBytes, _ := cmd.CombinedOutput()
	utils.StopAnimation()
	output := string(outputBytes)

	fmt.Println()

	if strings.TrimSpace(output) == "" {
		fmt.Println(utils.Bold + utils.Green + "User '" + username + "' added to group '" + groupname + "' successfully!" + utils.Reset)
	} else if strings.Contains(output, "NoSuchEntity") {
		fmt.Println(utils.Bold + utils.Red + "Error: Either the User or Group does not exist!" + utils.Reset)
	} else {
		fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
		fmt.Println(output)
	}
}
