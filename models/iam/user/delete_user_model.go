package user

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func DeleteIAMUser(username string) {
	// Check if user exists
	checkCmd := exec.Command("aws", "iam", "get-user", "--user-name", username)
	checkBytes, _ := checkCmd.CombinedOutput()
	if strings.Contains(string(checkBytes), "NoSuchEntity") {
		utils.StopAnimation()
		fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' does not exist!" + utils.Reset)
		return
	}

	utils.ShowProcessingAnimation("Checking IAM User Groups and Policies")

	groupCmd := exec.Command("aws", "iam", "list-groups-for-user", "--user-name", username, "--output", "text", "--query", "Groups[*].GroupName")
	groupBytes, _ := groupCmd.CombinedOutput()
	groups := strings.Fields(string(groupBytes))

	// Check attached policies
	policyCmd := exec.Command("aws", "iam", "list-attached-user-policies", "--user-name", username, "--output", "text", "--query", "AttachedPolicies[*].PolicyName")
	policyBytes, _ := policyCmd.CombinedOutput()
	policies := strings.Fields(string(policyBytes))

	if len(groups) > 0 || len(policies) > 0 {
		utils.StopAnimation()
		fmt.Println(utils.Yellow + "User '" + username + "' is a member of the following groups and/or has attached policies:" + utils.Reset)
		if len(groups) > 0 {
			fmt.Println(utils.Bold + "Groups:" + utils.Reset)
			for _, g := range groups {
				fmt.Println("  - " + g)
			}
		}
		if len(policies) > 0 {
			fmt.Println(utils.Bold + "Policies:" + utils.Reset)
			for _, p := range policies {
				fmt.Println("  - " + p)
			}
		}
		fmt.Print(utils.Red + "Do you want to remove the user from all groups and detach all policies, then delete the user? (y/N): " + utils.Reset)
		reader := bufio.NewReader(os.Stdin)
		answer, _ := reader.ReadString(' ')
		answer = strings.ToLower(strings.TrimSpace(answer))
		utils.ShowProcessingAnimation("Deleting IAM User")

		if answer != "y" && answer != "yes" {
			fmt.Println(utils.Yellow + "Aborted user deletion." + utils.Reset)
			return
		}
		// Remove user from all groups
		for _, g := range groups {
			exec.Command("aws", "iam", "remove-user-from-group", "--user-name", username, "--group-name", g).Run()
		}
		// Detach all policies
		for _, p := range policies {
			// Get policy ARN
			arnCmd := exec.Command("aws", "iam", "list-attached-user-policies", "--user-name", username, "--output", "text", "--query", "AttachedPolicies[?PolicyName=='"+p+"'].PolicyArn | [0]")
			arnBytes, _ := arnCmd.CombinedOutput()
			arn := strings.TrimSpace(string(arnBytes))
			if arn != "" {
				exec.Command("aws", "iam", "detach-user-policy", "--user-name", username, "--policy-arn", arn).Run()
			}
		}
	}

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
