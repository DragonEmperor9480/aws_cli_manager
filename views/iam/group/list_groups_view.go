package group

import (
	"bufio"
	"fmt"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func ShowGroupsTable(data string) {
	fmt.Println(utils.Bold + "\n┌────────────────────┬───────────────────────┬──────────────────────────┐" + utils.Reset)
	fmt.Println(utils.Bold + "│    Group Name      │       Group ID        │       Created At         │" + utils.Reset)
	fmt.Println(utils.Bold + "├────────────────────┼───────────────────────┼──────────────────────────┤" + utils.Reset)

	scanner := bufio.NewScanner(strings.NewReader(data))
	for scanner.Scan() {
		cols := strings.Fields(scanner.Text())
		if len(cols) >= 3 {
			groupName := cols[0]
			groupID := cols[1]
			createdAt := strings.Join(cols[2:], " ")
			fmt.Printf(utils.Bold+"│ %-18s │ %-20s │ %-24s │"+utils.Reset+"\n", groupName, groupID, createdAt)
		}
	}

	fmt.Println(utils.Bold + "└────────────────────┴───────────────────────┴──────────────────────────┘" + utils.Reset)
}
