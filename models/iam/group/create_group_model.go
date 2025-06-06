package group

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func CreateIAMGroup(groupname string) {
	// Start animation in background
	utils.ShowProcessingAnimation("Creating IAM Group")

	// Execute AWS command
	cmd := exec.Command("aws", "iam", "create-group", "--group-name", groupname)
	outputBytes, _ := cmd.CombinedOutput()
	output := string(outputBytes)

	// Stop animation and print a newline
	utils.StopAnimation()
	fmt.Println()

	// Handle output
	if strings.Contains(output, "already exists") {
		fmt.Println(utils.Bold + utils.Red + "Error: Group '" + groupname + "' already exists!" + utils.Reset)
	} else if strings.Contains(output, "GroupName") {
		fmt.Println(utils.Bold + utils.Green + "Group '" + groupname + "' created successfully!" + utils.Reset)
	} else {
		fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
		fmt.Println(output)
	}
}
