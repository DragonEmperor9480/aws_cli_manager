package group

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	groupModel "github.com/DragonEmperor9480/aws_cli_manager/models/iam/group"
	userModel "github.com/DragonEmperor9480/aws_cli_manager/models/iam/user"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	views "github.com/DragonEmperor9480/aws_cli_manager/views/iam/group"
)

func RemoveUserFromGroupController() {
	utils.ShowProcessingAnimation("Fetching IAM Users and IAM Groups")
	users := userModel.FetchOnlyUsernames()
	groups := groupModel.FetchOnlyGroupNames()
	utils.StopAnimation()
	views.ShowUsersAndGroupsSideBySide(users, groups)

	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Enter Username: ")
	input, _ := reader.ReadString('\n')
	username := strings.TrimSpace(input)

	userGroups := groupModel.ListUserGroupsModel(username)
	utils.ShowProcessingAnimation("Fetching IAM Groups for The User")
	x := views.ShowGroupsOfUser(username, userGroups)
	if !x {
		utils.StopAnimation()
		return
	}
	utils.StopAnimation()

	fmt.Print("Enter Groupname: ")
	input, _ = reader.ReadString('\n')
	groupname := strings.TrimSpace(input)

	if username == "" || groupname == "" {
		fmt.Println(utils.Bold + utils.Red + "Both username and groupname must be provided!" + utils.Reset)
		return
	}

	groupModel.RemoveUserFromGroupModel(username, groupname)

}
