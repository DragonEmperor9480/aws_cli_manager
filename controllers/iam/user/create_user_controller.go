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
	input, _ := reader.ReadString('\n')
	username := strings.TrimSpace(input)

	if username == "" {
		fmt.Println(utils.Bold + utils.Red + "Please enter a valid name" + utils.Reset)
		return
	}

	create_user_model.CreateIAMUser(username)

	fmt.Print("Would you like to create set Initial password for the user? (y/n) (Default = n): ")
	saveChoice, _ := reader.ReadString('\n')
	saveChoice = strings.ToLower(strings.TrimSpace(saveChoice))
	if (saveChoice == "y"||saveChoice=="Y") {
		SetInitialUserPasswordDirect(username)

	}else{
		fmt.Println(utils.Bold + utils.Yellow + "Skipping Initial Password Setup" + utils.Reset)
	}
	fmt.Print("Would you like to create access key for the user? (y/n) (Default = n): ")
	saveChoice, _ = reader.ReadString('\n')
	saveChoice = strings.ToLower(strings.TrimSpace(saveChoice))
	if saveChoice == "y" {
		create_user_model.CreateAccessKeyForUserModel(username)
	}else{
		fmt.Println(utils.Bold + utils.Yellow + "Skipping Access Key Creation" + utils.Reset)
	}

}
