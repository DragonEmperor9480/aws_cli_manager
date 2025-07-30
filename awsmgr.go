package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/controllers"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"github.com/DragonEmperor9480/aws_cli_manager/views"
)

func main() {
	reader := bufio.NewReader(os.Stdin)

	for {
		utils.ClearScreen()
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
			fmt.Println("EC2 MANAGEMENT(WIP)")
			fmt.Println("────────────────────────────────────")
			controllers.EC2_mgr()
		case "3":
			fmt.Println()
			fmt.Println("S3 MANAGEMENT(WIP)")
			fmt.Println("────────────────────────────────────")
			controllers.S3_mgr()
		case "4":
			fmt.Println("\nExiting AWS CLI Manager...")
			return
		default:
			fmt.Println("\nInvalid selection. Please try again.")
		}
	}
}
