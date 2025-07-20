package group

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	model "github.com/DragonEmperor9480/aws_cli_manager/models/iam/group"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	view "github.com/DragonEmperor9480/aws_cli_manager/views/iam/group"
)

func ListUserGroupsController() {
	reader := bufio.NewReader(os.Stdin)
	ListUsersController()
	fmt.Print("Enter username: ")
	input, _ := reader.ReadString('\n')
	username := strings.TrimSpace(input)
	utils.ShowProcessingAnimation("Fetching IAM Groups for User")
	GetGroups := model.ListUserGroupsModel(username)
	utils.StopAnimation()
	view.ShowGroupsOfUser(username, GetGroups)

}
