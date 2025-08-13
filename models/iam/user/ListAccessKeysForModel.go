package user

import (
	"os/exec"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	user_view "github.com/DragonEmperor9480/aws_cli_manager/views/iam/user"
)

func ListAccessKeysForUserModel(username string) {
	utils.ShowProcessingAnimation("Listing access keys for user: " + username)
	cmd := exec.Command("aws", "iam", "list-access-keys", "--user-name", username)
	output, err := cmd.CombinedOutput()
	if err != nil {
		utils.StopAnimation()
		println("Error listing access keys:", err.Error())
		return
	}
	utils.StopAnimation()
	user_view.ListAccessKeysForUserView(string(output))
}
