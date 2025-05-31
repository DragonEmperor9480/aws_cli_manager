package controllers

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	iamview "github.com/DragonEmperor9480/aws_cli_manager/views/iam"
)

func IAM_mgr() {
	reader := bufio.NewReader(os.Stdin)

	for {
		iamview.ShowIAMMenu()

		fmt.Print("Choose an option: ")
		input, _ := reader.ReadString('\n')  // FIXED HERE
		input = strings.TrimSpace(input)

		switch input {
		case "1":
			// Call: CreateIAMUser()
			utils.Bk()
		case "2":
			// Call: ListIAMUsers()
			utils.Bk()
		case "3":
			// Call: AddUserToGroup()
			utils.Bk()
		case "4":
			// Call: DeleteIAMUser()
			utils.Bk()
		case "5":
			// Call: SetInitialPassword()
			utils.Bk()
		case "6":
			// Call: UpdatePassword()
			utils.Bk()
		case "9":
			// Call: CreateIAMGroup()
			utils.Bk()
		case "10":
			// Call: ListIAMGroups()
			utils.Bk()
		case "11":
			// Call: ListUsersInGroup()
			utils.Bk()
		case "12":
			// Call: ListUserGroups()
			utils.Bk()
		case "13":
			// Call: DeleteIAMGroup()
			utils.Bk()
		case "14":
			// Call: RemoveUserFromGroup()
			utils.Bk()
		case "15":
			fmt.Println("Returning to Main Menu...")
			return
		default:
			fmt.Println(utils.Red + "Invalid input. Please try again." + utils.Reset)
			utils.Bk()
		}
	}
}
