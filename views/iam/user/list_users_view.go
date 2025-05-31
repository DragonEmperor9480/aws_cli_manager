package userview

import (
	"fmt"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func RenderIAMUsersTable(raw string) {
	fmt.Println()
	fmt.Println(utils.Bold + "┌────────────────┬────────────────────────────────┬──────────────────────────┐" + utils.Reset)
	fmt.Println(utils.Bold + "│   Username     │             User ID            │      Created At          │" + utils.Reset)
	fmt.Println(utils.Bold + "├────────────────┼────────────────────────────────┼──────────────────────────┤" + utils.Reset)

	lines := strings.Split(raw, "\n")
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) >= 3 {
			fmt.Printf(utils.Bold+"│ %-14s │ %-30s │ %-24s │"+utils.Reset+"\n", fields[0], fields[1], fields[2])
		}
	}

	fmt.Println(utils.Bold + "└────────────────┴────────────────────────────────┴──────────────────────────┘" + utils.Reset)
}
