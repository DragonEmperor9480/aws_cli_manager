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

// CreateIAMUserWithPassword creates a user and sets initial password in one operation
// Returns user creation status code, password status code, and error
func CreateIAMUserWithPassword(username, password string, requireReset bool) (int, int, error) {
	// First create the user
	userStatus, err := CreateIAMUser(username)

	// If user creation failed, return immediately
	if userStatus != UserCreatedSuccess {
		return userStatus, 0, err
	}

	// User created successfully, now set password
	passwordStatus, passwordErr := SetInitialUserPasswordModel(username, password, requireReset)

	return userStatus, passwordStatus, passwordErr
}
