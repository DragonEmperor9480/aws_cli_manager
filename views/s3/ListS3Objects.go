package s3

import (
	"fmt"
	"strconv"
	"strings"
)

func PrintError(msg string) {
	fmt.Printf("%s\n", msg)
}

func PrintWarning(msg string) {
	fmt.Printf("%s\n", msg)
}

func PrintS3Objects(lines []string) {
	fmt.Println("┌──────────────────────┬────────────────────────────────┬────────────────────────┐")
	fmt.Println("│     Date Created     │          Object Name           │    Object Size (KB)    │")
	fmt.Println("├──────────────────────┼────────────────────────────────┼────────────────────────┤")

	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) < 4 {
			continue
		}
		date := fields[0]
		time := fields[1]
		sizeStr := fields[2]
		objectName := strings.Join(fields[3:], " ")

		size, _ := strconv.Atoi(sizeStr)
		sizeKB := (size + 1023) / 1024

		if len(objectName) > 25 {
			objectName = objectName[:22] + "..."
		}

		fmt.Printf("│ %-10s %-9s │ %-30s │ %10d KB          │\n",
			date, time, objectName, sizeKB)
	}

	fmt.Println("└──────────────────────┴────────────────────────────────┴────────────────────────┘")
}
