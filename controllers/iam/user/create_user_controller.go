package user

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	create_user_model "github.com/DragonEmperor9480/aws_cli_manager/models/iam/user"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func CreateIAMUserController() {
	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Enter Username for new IAM User: ")
	input, _ := reader.ReadString(' ')
	username := strings.TrimSpace(input)

	if username == "" {
		fmt.Println(utils.Bold + utils.Red + "Please enter a valid name" + utils.Reset)
		return
	}

	create_user_model.CreateIAMUser(username)

	fmt.Println("Would you like to create set Initial password for the user? (y/n): ")
	saveChoice, _ := reader.ReadString('\n')
	saveChoice = strings.ToLower(strings.TrimSpace(saveChoice))
	if saveChoice == "y" {
		SetInitialUserPasswordDirect(username)

	}
	fmt.Println("Would you like to create access key for the user? (y/n): ")
	saveChoice, _ = reader.ReadString('\n')
	saveChoice = strings.ToLower(strings.TrimSpace(saveChoice))
	if saveChoice == "y" {
		create_user_model.CreateAccessKeyForUserModel(username)
	}

}
