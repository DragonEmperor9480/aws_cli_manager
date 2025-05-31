package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/controllers"
	"github.com/DragonEmperor9480/aws_cli_manager/views"
)

func main() {
	reader := bufio.NewReader(os.Stdin)

	for {
		views.ShowMenu()

		fmt.Print("Select option [1-4]: ")
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		switch input {
		case "1":
			fmt.Println()
			fmt.Println("IAM MANAGEMENT")
			fmt.Println("────────────────────────────────────")
			controllers.IAM_mgr()
		case "2":
			fmt.Println()
			fmt.Println("EC2 MANAGEMENT")
			fmt.Println("────────────────────────────────────")
			//controllers.ec2_manager()
		case "3":
			fmt.Println()
			fmt.Println("S3 MANAGEMENT")
			fmt.Println("────────────────────────────────────")
			//controllers.s3_manager()
		case "4":
			fmt.Println("\nExiting AWS CLI Manager...")
			return
		default:
			fmt.Println("\nInvalid selection. Please try again.")
		}
	}
}
