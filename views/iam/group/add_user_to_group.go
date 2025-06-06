package group

import (
	"fmt"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

// Display only usernames and group names side-by-side
func ShowUsersAndGroupsSideBySide(users []string, groups []string) {
	fmt.Println()
	fmt.Println(utils.Bold + "┌────────────────────────────┬────────────────────────────┐" + utils.Reset)
	fmt.Println(utils.Bold + "│         IAM Users          │        IAM Groups          │" + utils.Reset)
	fmt.Println(utils.Bold + "├────────────────────────────┼────────────────────────────┤" + utils.Reset)

	maxRows := len(users)
	if len(groups) > maxRows {
		maxRows = len(groups)
	}

	for i := 0; i < maxRows; i++ {
		user := ""
		group := ""

		if i < len(users) {
			user = users[i]
		}
		if i < len(groups) {
			group = groups[i]
		}

		fmt.Printf(utils.Bold+"│ %-26s │ %-26s │"+utils.Reset+"\n", user, group)
	}

	fmt.Println(utils.Bold + "└────────────────────────────┴────────────────────────────┘" + utils.Reset)
}
