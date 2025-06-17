package group

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func DeleteGroupModel(groupname string) {
	// Check if group exists
	utils.ShowProcessingAnimation("Checking group existence...")
	cmd := exec.Command("aws", "iam", "get-group", "--group-name", groupname)
	if err := cmd.Run(); err != nil {
		utils.StopAnimation()
		fmt.Println(utils.Red + utils.Bold + "Error: Group '" + groupname + "' does not exist." + utils.Reset)
		return
	}
	utils.StopAnimation()

	fmt.Println(utils.Bold + "\nChecking dependencies for group '" + groupname + "'..." + utils.Reset)
	utils.ShowProcessingAnimation(" ")

	// Fetch attached policies
	cmd = exec.Command("aws", "iam", "list-attached-group-policies", "--group-name", groupname, "--query", "AttachedPolicies[*].PolicyName", "--output", "text")
	policyBytes, _ := cmd.Output()
	policies := strings.Fields(string(policyBytes))

	// Fetch users
	cmd = exec.Command("aws", "iam", "get-group", "--group-name", groupname, "--query", "Users[*].UserName", "--output", "text")
	userBytes, _ := cmd.Output()
	users := strings.Fields(string(userBytes))

	if len(policies) > 0 || len(users) > 0 {
		fmt.Println(utils.Yellow + "Group '" + groupname + "' has the following dependencies:" + utils.Reset)
		if len(policies) > 0 {
			fmt.Println(utils.Yellow+"- Policies:", strings.Join(policies, ", ")+utils.Reset)
		}
		if len(users) > 0 {
			fmt.Println(utils.Yellow+"- Users:", strings.Join(users, ", ")+utils.Reset)
		}
		utils.StopAnimation()
		fmt.Print(utils.Bold + "\nDo you want to detach policies and remove users before deleting? (y/n): " + utils.Reset)

		reader := bufio.NewReader(os.Stdin)
		input, _ := reader.ReadString('\n')
		if strings.TrimSpace(strings.ToLower(input)) != "y" {
			fmt.Println(utils.Red + utils.Bold + "Group deletion aborted." + utils.Reset)
			return
		}
	}

	// Detach policies
	if len(policies) > 0 {
		utils.ShowProcessingAnimation("Detaching policies...")
		for _, policy := range policies {
			policyArn := "arn:aws:iam::aws:policy/" + policy
			exec.Command("aws", "iam", "detach-group-policy", "--group-name", groupname, "--policy-arn", policyArn).Run()
		}
		utils.StopAnimation()
		fmt.Println(utils.Yellow + "Detached all managed policies from '" + groupname + "'." + utils.Reset)
	}

	// Remove users
	if len(users) > 0 {
		utils.ShowProcessingAnimation("Removing users from group...")
		for _, user := range users {
			exec.Command("aws", "iam", "remove-user-from-group", "--group-name", groupname, "--user-name", user).Run()
		}
		utils.StopAnimation()
		fmt.Println(utils.Yellow + "Removed all users from '" + groupname + "'." + utils.Reset)
	}

	// Delete group
	utils.ShowProcessingAnimation("Deleting group '" + groupname + "'...")
	cmd = exec.Command("aws", "iam", "delete-group", "--group-name", groupname)
	err := cmd.Run()
	utils.StopAnimation()

	if err != nil {
		fmt.Println(utils.Red + utils.Bold + "Error: Failed to delete group '" + groupname + "'." + utils.Reset)
	} else {
		fmt.Println(utils.Green + utils.Bold + "Group '" + groupname + "' deleted successfully!" + utils.Reset)
	}
}
