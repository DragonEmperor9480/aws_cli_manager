package user

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	user_model "github.com/DragonEmperor9480/aws_cli_manager/models/iam/user"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func SetInitialUserPassword() {
	ListUsersController()

	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Enter Username to set password for: ")
	input, _ := reader.ReadString('\n')
	username := strings.TrimSpace(input)

	if username == "" {
		fmt.Println(utils.Bold + utils.Red + "Please enter a valid username." + utils.Reset)
		return
	}

	fmt.Print("Enter Password for the user: ")
	input, _ = reader.ReadString('\n')
	password := strings.TrimSpace(input)

	if password == "" {
		fmt.Println(utils.Bold + utils.Red + "Please enter a valid password." + utils.Reset)
		return
	}

	user_model.SetInitialUserPasswordModel(username, password)
}
