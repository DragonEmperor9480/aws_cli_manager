package user

import (
	"context"
	"fmt"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/iam"
)

func CreateIAMUser(username string) {
	// Start animation in background
	utils.ShowProcessingAnimation("Creating IAM User")

	// Execute AWS SDK call
	ctx := context.TODO()
	_, err := utils.IAMClient.CreateUser(ctx, &iam.CreateUserInput{
		UserName: aws.String(username),
	})

	// Stop animation and print a newline
	utils.StopAnimation()
	fmt.Println()

	if err != nil {
		if strings.Contains(err.Error(), "EntityAlreadyExists") {
			fmt.Println(utils.Bold + utils.Red + "Error: User '" + username + "' already exists!" + utils.Reset)
		} else {
			fmt.Println(utils.Yellow + "Unexpected error occurred:" + utils.Reset)
			fmt.Println(err.Error())
		}
		return
	}

	fmt.Println(utils.Bold + utils.Green + "User '" + username + "' created successfully!" + utils.Reset)
}
