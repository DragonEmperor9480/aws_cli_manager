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
	utils.ShowProcessingAnimation("Processing")
	// Check if user exists
	checkCmd := exec.Command("aws", "iam", "get-user", "--user-name", username)
	checkBytes, _ := checkCmd.CombinedOutput()
	reader := bufio.NewReader(os.Stdin)
	
	utils.StopAnimation()
	
	if strings.Contains(string(checkBytes), "NoSuchEntity") {
		fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' does not exist!" + utils.Reset)
		return
	}
	
	utils.ShowProcessingAnimation("Checking IAM User dependencies...")

	// Get groups
	groupCmd := exec.Command("aws", "iam", "list-groups-for-user", "--user-name", username, "--output", "text", "--query", "Groups[*].GroupName")
	groupBytes, _ := groupCmd.CombinedOutput()
	groups := strings.Fields(string(groupBytes))

	// Get attached managed policies
	policyCmd := exec.Command("aws", "iam", "list-attached-user-policies", "--user-name", username, "--output", "text", "--query", "AttachedPolicies[*].PolicyName")
	policyBytes, _ := policyCmd.CombinedOutput()
	policies := strings.Fields(string(policyBytes))

	// Get inline policies
	inlineCmd := exec.Command("aws", "iam", "list-user-policies", "--user-name", username, "--output", "text", "--query", "PolicyNames[*]")
	inlineBytes, _ := inlineCmd.CombinedOutput()
	inlinePolicies := strings.Fields(string(inlineBytes))

	// Get access keys
	keyCmd := exec.Command("aws", "iam", "list-access-keys", "--user-name", username, "--output", "text", "--query", "AccessKeyMetadata[*].AccessKeyId")
	keyBytes, _ := keyCmd.CombinedOutput()
	accessKeys := strings.Fields(string(keyBytes))

	utils.StopAnimation()
	
	if len(groups) > 0 || len(policies) > 0 || len(inlinePolicies) > 0 || len(accessKeys) > 0 {
		fmt.Println(utils.Yellow + "User '" + username + "' has the following dependencies:" + utils.Reset)

		if len(groups) > 0 {
			fmt.Println(utils.Bold + "Groups:" + utils.Reset)
			for _, g := range groups {
				fmt.Println("  - " + g)
			}
		}
		if len(policies) > 0 {
			fmt.Println(utils.Bold + "Managed Policies:" + utils.Reset)
			for _, p := range policies {
				fmt.Println("  - " + p)
			}
		}
		if len(inlinePolicies) > 0 {
			fmt.Println(utils.Bold + "Inline Policies:" + utils.Reset)
			for _, p := range inlinePolicies {
				fmt.Println("  - " + p)
			}
		}
		if len(accessKeys) > 0 {
			fmt.Println(utils.Bold + "Access Keys:" + utils.Reset)
			for _, k := range accessKeys {
				fmt.Println("  - " + k)
			}
		}

		fmt.Print(utils.Red + "Do you want to remove all dependencies and delete the user? (y/N): " + utils.Reset)
		answer, _ := reader.ReadString('\n')
		answer = strings.ToLower(strings.TrimSpace(answer))

		if answer != "y" && answer != "yes" {
			fmt.Println(utils.Yellow + "Aborted user deletion." + utils.Reset)
			return
		}

		utils.ShowProcessingAnimation("Cleaning up IAM User dependencies")

		// Remove user from all groups
		for _, g := range groups {
			exec.Command("aws", "iam", "remove-user-from-group", "--user-name", username, "--group-name", g).Run()
		}

		// Detach all managed policies
		for _, p := range policies {
			arnCmd := exec.Command("aws", "iam", "list-attached-user-policies", "--user-name", username, "--output", "text", "--query", "AttachedPolicies[?PolicyName=='"+p+"'].PolicyArn | [0]")
			arnBytes, _ := arnCmd.CombinedOutput()
			arn := strings.TrimSpace(string(arnBytes))
			if arn != "" {
				exec.Command("aws", "iam", "detach-user-policy", "--user-name", username, "--policy-arn", arn).Run()
			}
		}

		// Delete all inline policies
		for _, p := range inlinePolicies {
			exec.Command("aws", "iam", "delete-user-policy", "--user-name", username, "--policy-name", p).Run()
		}

		// Deactivate & delete access keys
		for _, k := range accessKeys {
			exec.Command("aws", "iam", "update-access-key", "--user-name", username, "--access-key-id", k, "--status", "Inactive").Run()
			exec.Command("aws", "iam", "delete-access-key", "--user-name", username, "--access-key-id", k).Run()
		}

	}
	utils.StopAnimation()
	// Delete login profile if exists
	loginProfileCmd := exec.Command("aws", "iam", "get-login-profile", "--user-name", username)
	loginProfileBytes, _ := loginProfileCmd.CombinedOutput()
	if !strings.Contains(string(loginProfileBytes), "NoSuchEntity") {
		fmt.Println("Would you like to delete the login profile for the user? (y/N): ")
		deleteLoginProfileChoice, _ := reader.ReadString(' ')
		deleteLoginProfileChoice = strings.ToLower(strings.TrimSpace(deleteLoginProfileChoice))
		if deleteLoginProfileChoice == "y" || deleteLoginProfileChoice == "yes" {

			exec.Command("aws", "iam", "delete-login-profile", "--user-name", username).Run()
		}
	}
	// Delete the IAM user
	utils.ShowProcessingAnimation("Deleting IAM User")
	cmd := exec.Command("aws", "iam", "delete-user", "--user-name", username)
	outputBytes, _ := cmd.CombinedOutput()
	utils.StopAnimation()
	fmt.Println()

	if strings.Contains(string(outputBytes), "NoSuchEntity") {
		fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' does not exist!" + utils.Reset)
	} else if strings.TrimSpace(string(outputBytes)) == "" {
		fmt.Println(utils.Bold + utils.Green + "User '" + username + "' deleted successfully!" + utils.Reset)
	} else {
		fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
		fmt.Println(string(outputBytes))
	}
}
