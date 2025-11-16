package user

import (
	"context"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/iam"
)

// Status codes for CreateIAMUser
const (
	UserAlreadyExists  = 1
	UserCreationError  = 2
	UserCreatedSuccess = 3
)

func CreateIAMUser(username string) (int, error) {
	// Execute AWS SDK call
	ctx := context.TODO()
	_, err := utils.IAMClient.CreateUser(ctx, &iam.CreateUserInput{
		UserName: aws.String(username),
	})

	if err != nil {
		if strings.Contains(err.Error(), "EntityAlreadyExists") {
			return UserAlreadyExists, nil
		}
		return UserCreationError, err
	}
	return UserCreatedSuccess, nil
}
