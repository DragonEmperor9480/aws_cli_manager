package user

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func CreateIAMUser(username string) {
	// Start animation in background
	utils.ShowProcessingAnimation("Creating IAM User")

	// Execute AWS command
	cmd := exec.Command("aws", "iam", "create-user", "--user-name", username)
	outputBytes, _ := cmd.CombinedOutput()
	output := string(outputBytes)

	// Stop animation and print a newline
	utils.StopAnimation()
	fmt.Println()

	// Handle output
	if strings.Contains(output, "EntityAlreadyExists") {
		fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' already exists!" + utils.Reset)
	} else if strings.Contains(output, "UserName") {
		fmt.Println(utils.Bold + utils.Green + "User '" + username + "' created successfully!" + utils.Reset)
	} else {
		fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
		fmt.Println(output)
	}
}
