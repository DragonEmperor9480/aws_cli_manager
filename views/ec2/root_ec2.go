package ec2

import (
	"fmt"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func ShowEC2Menu() {
	fmt.Println(utils.Cyan + "EC2 Management Module" + utils.Reset)
	fmt.Println("────────────────────────────────────")
	fmt.Println(utils.Yellow + "This module is still in development..." + utils.Reset)
	fmt.Println()

	// Simple animation text (dots will be printed in controller)
	fmt.Print(utils.Blue + "Loading development preview" + utils.Reset)
}
