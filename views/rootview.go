package views

import (
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"fmt"
)

func ShowMenu() {
	fmt.Println(utils.Bold + utils.Blue + "┌─────────────────────────────────┐" + utils.Reset)
	fmt.Println(utils.Bold + utils.Blue + "│        AWS CLI MANAGER v1.0.0   │ " + utils.Cyan + "STABLE" + utils.Reset)
	fmt.Println(utils.Bold + utils.Blue + "└─────────────────────────────────┘" + utils.Reset)
	fmt.Println(utils.Cyan + "Available services:" + utils.Reset)
	fmt.Println("────────────────────────────────────")
	fmt.Println(utils.Bold + utils.Blue + "[1]" + utils.Reset + " " + utils.Bold + "IAM" + utils.Reset + " - Identity and Access Management")
	fmt.Println(utils.Bold + utils.Blue + "[2]" + utils.Reset + " " + utils.Bold + "EC2" + utils.Reset + " - Elastic Compute Cloud")
	fmt.Println(utils.Bold + utils.Blue + "[3]" + utils.Reset + " " + utils.Bold + "S3" + utils.Reset + "  - Simple Storage Service")
	fmt.Println(utils.Bold + utils.Red + "[4]" + utils.Reset + " " + utils.Bold + "Exit" + utils.Reset)
	fmt.Println("────────────────────────────────────")
}
