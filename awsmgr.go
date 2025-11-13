package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/controllers"
	"github.com/DragonEmperor9480/aws_cli_manager/db_service"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"github.com/DragonEmperor9480/aws_cli_manager/views"
)

func main() {
	// Check for version flag
	if len(os.Args) > 1 && (os.Args[1] == "--version" || os.Args[1] == "-v") {
		utils.GetVersion()
		return
	}

	// Initialize database
	if err := db_service.InitDB(); err != nil {
		fmt.Println(utils.Red + "Error initializing database: " + err.Error() + utils.Reset)
		fmt.Println(utils.Yellow + "Credentials will not be saved." + utils.Reset)
	}

	reader := bufio.NewReader(os.Stdin)

	for {
		utils.ClearScreen()
		views.ShowMenu()

		fmt.Print("Select option [1-5]: ")
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
			fmt.Println()
			fmt.Println("CLOUDWATCH MANAGEMENT")
			fmt.Println("────────────────────────────────────")
			controllers.CloudWatch_mgr()
		case "5":
			fmt.Println("\nExiting AWS CLI Manager...")
			return
		default:
			fmt.Println("\nInvalid selection. Please try again.")
		}
	}
}
