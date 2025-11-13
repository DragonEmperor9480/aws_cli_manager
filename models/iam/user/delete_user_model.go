package user

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/iam"
)

func DeleteIAMUser(username string) {
	ctx := context.TODO()
	reader := bufio.NewReader(os.Stdin)

	utils.ShowProcessingAnimation("Processing")

	// Check if user exists
	_, err := utils.IAMClient.GetUser(ctx, &iam.GetUserInput{
		UserName: aws.String(username),
	})

	utils.StopAnimation()

	if err != nil && strings.Contains(err.Error(), "NoSuchEntity") {
		fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' does not exist!" + utils.Reset)
		return
	}

	utils.ShowProcessingAnimation("Checking IAM User dependencies...")

	// Get groups
	groupsResult, _ := utils.IAMClient.ListGroupsForUser(ctx, &iam.ListGroupsForUserInput{
		UserName: aws.String(username),
	})
	var groups []string
	for _, g := range groupsResult.Groups {
		groups = append(groups, aws.ToString(g.GroupName))
	}

	// Get attached managed policies
	policiesResult, _ := utils.IAMClient.ListAttachedUserPolicies(ctx, &iam.ListAttachedUserPoliciesInput{
		UserName: aws.String(username),
	})
	var policies []string
	var policyArns []string
	for _, p := range policiesResult.AttachedPolicies {
		policies = append(policies, aws.ToString(p.PolicyName))
		policyArns = append(policyArns, aws.ToString(p.PolicyArn))
	}

	// Get inline policies
	inlineResult, _ := utils.IAMClient.ListUserPolicies(ctx, &iam.ListUserPoliciesInput{
		UserName: aws.String(username),
	})
	inlinePolicies := inlineResult.PolicyNames

	// Get access keys
	keysResult, _ := utils.IAMClient.ListAccessKeys(ctx, &iam.ListAccessKeysInput{
		UserName: aws.String(username),
	})
	var accessKeys []string
	for _, k := range keysResult.AccessKeyMetadata {
		accessKeys = append(accessKeys, aws.ToString(k.AccessKeyId))
	}

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
			utils.IAMClient.RemoveUserFromGroup(ctx, &iam.RemoveUserFromGroupInput{
				UserName:  aws.String(username),
				GroupName: aws.String(g),
			})
		}

		// Detach all managed policies
		for _, arn := range policyArns {
			utils.IAMClient.DetachUserPolicy(ctx, &iam.DetachUserPolicyInput{
				UserName:  aws.String(username),
				PolicyArn: aws.String(arn),
			})
		}

		// Delete all inline policies
		for _, p := range inlinePolicies {
			utils.IAMClient.DeleteUserPolicy(ctx, &iam.DeleteUserPolicyInput{
				UserName:   aws.String(username),
				PolicyName: aws.String(p),
			})
		}

		// Delete access keys
		for _, k := range accessKeys {
			utils.IAMClient.DeleteAccessKey(ctx, &iam.DeleteAccessKeyInput{
				UserName:    aws.String(username),
				AccessKeyId: aws.String(k),
			})
		}
	}

	utils.StopAnimation()

	// Delete login profile if exists
	_, err = utils.IAMClient.GetLoginProfile(ctx, &iam.GetLoginProfileInput{
		UserName: aws.String(username),
	})
	if err == nil {
		fmt.Print("Would you like to delete the login profile for the user? (y/N): ")
		deleteLoginProfileChoice, _ := reader.ReadString('\n')
		deleteLoginProfileChoice = strings.ToLower(strings.TrimSpace(deleteLoginProfileChoice))
		if deleteLoginProfileChoice == "y" || deleteLoginProfileChoice == "yes" {
			utils.IAMClient.DeleteLoginProfile(ctx, &iam.DeleteLoginProfileInput{
				UserName: aws.String(username),
			})
		}
	}

	// Delete the IAM user
	utils.ShowProcessingAnimation("Deleting IAM User")
	_, err = utils.IAMClient.DeleteUser(ctx, &iam.DeleteUserInput{
		UserName: aws.String(username),
	})
	utils.StopAnimation()
	fmt.Println()

	if err != nil {
		if strings.Contains(err.Error(), "NoSuchEntity") {
			fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' does not exist!" + utils.Reset)
		} else {
			fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
			fmt.Println(err.Error())
		}
		return
	}

	fmt.Println(utils.Bold + utils.Green + "User '" + username + "' deleted successfully!" + utils.Reset)
}
