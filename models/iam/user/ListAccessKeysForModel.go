package user

import (
	"os/exec"

	user_view "github.com/DragonEmperor9480/aws_cli_manager/views/iam/user"
)

func ListAccessKeysForUserModel(username string) {

	cmd := exec.Command("aws", "iam", "list-access-keys", "--user-name", username)
	output, err := cmd.CombinedOutput()
	if err != nil {
		println("Error listing access keys:", err.Error())
		return
	}
	user_view.ListAccessKeysForUserView(string(output))
}
