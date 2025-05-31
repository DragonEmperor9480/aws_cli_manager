package usercontroller

import (
	"fmt"

	"github.com/DragonEmperor9480/aws_cli_manager/models/iam/user"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	userview "github.com/DragonEmperor9480/aws_cli_manager/views/iam/user"
)

func ListUsers_mgr() {
	utils.ShowProcessingAnimation("Loading IAM Users")
	data, err := iam.FetchIAMUsers()
	utils.StopAnimation()

	if err != nil {
		fmt.Println(utils.Red + "Failed to fetch IAM users: " + err.Error() + utils.Reset)
		return
	}

	userview.RenderIAMUsersTable(data)
}
