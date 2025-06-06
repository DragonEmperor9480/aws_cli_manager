package group

import (
	"fmt"

	model "github.com/DragonEmperor9480/aws_cli_manager/models/iam/group"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	view "github.com/DragonEmperor9480/aws_cli_manager/views/iam/group"
)

func ListGroupsController() {
	utils.ShowProcessingAnimation("Loading IAM Groups")
	output, err := model.FetchIAMGroups()
	utils.StopAnimation()
	fmt.Println()

	if err != nil {
		fmt.Println(utils.Bold + utils.Red + "Error fetching IAM groups!" + utils.Reset)
		fmt.Println(output)
		return
	}

	view.ShowGroupsTable(output)
}
