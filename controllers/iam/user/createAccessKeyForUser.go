package user

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	model "github.com/DragonEmperor9480/aws_cli_manager/models/iam/user"
)

func CreateAccessKeyForUserController() {
	reader := bufio.NewReader(os.Stdin)
	ListUsersController()
	fmt.Println("Enter IAM username to create access key for:")
	input, _ := reader.ReadString(' ')
	username := strings.TrimSpace(input)
	model.CreateAccessKeyForUserModel(username)

}
