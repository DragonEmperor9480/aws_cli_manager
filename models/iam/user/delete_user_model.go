package user

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func DeleteIAMUser(username string) {

	utils.ShowProcessingAnimation("Deleting IAM User")

	cmd := exec.Command("aws", "iam", "delete-user", "--user-name", username)
	outputBytes, _ := cmd.CombinedOutput()
	output := string(outputBytes)

	utils.StopAnimation()
	fmt.Println()

	if strings.Contains(output, "NoSuchEntity") {
		fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' does not exist!" + utils.Reset)
	} else if strings.Contains(output, "") {
		fmt.Println(utils.Bold + utils.Green + "User '" + username + "' deleted successfully!" + utils.Reset)
	} else {
		fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
		fmt.Println(output)
	}
}
