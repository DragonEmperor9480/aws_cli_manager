package s3

import (
	"fmt"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func RenderS3BucketsTable(raw string) {
	fmt.Println()
	fmt.Println(utils.Bold + "┌──────────────────────────────┬──────────────────────────┬────────────────────────────┐" + utils.Reset)
	fmt.Println(utils.Bold + "│        Bucket Name           │        Created Date      │        Created Time        │" + utils.Reset)
	fmt.Println(utils.Bold + "├──────────────────────────────┼──────────────────────────┼────────────────────────────┤" + utils.Reset)

	lines := strings.Split(raw, "\n")
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		fields := strings.Fields(line)
		// aws s3 ls output: Date Time BucketName
		if len(fields) >= 3 {
			date := fields[0]
			time := fields[1]
			bucketName := fields[2]
			fmt.Printf(utils.Bold+"│ %-28s │ %-24s │ %-26s │"+utils.Reset+"\n", bucketName, date, time)
		}
	}

	fmt.Println(utils.Bold + "└──────────────────────────────┴──────────────────────────┴────────────────────────────┘" + utils.Reset)
}
