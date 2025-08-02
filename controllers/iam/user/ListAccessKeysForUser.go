package user

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	user_model "github.com/DragonEmperor9480/aws_cli_manager/models/iam/user"
)

func ListAccessKeysForUserController() {
	ListUsersController()

	reader := bufio.NewReader(os.Stdin)
	fmt.Println("Enter Username to list access keys for: ")
	input, _ := reader.ReadString('\n')
	username := strings.TrimSpace(input)

	cond := user_model.UserExistsOrNotModel(username)
	if !cond {
		fmt.Println("User does not exist.")
		return
	}
	user_model.ListAccessKeysForUserModel(username)

}
