package controllers

import (
	"bufio"
	"fmt"
	"os"
	"time"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	ec2view "github.com/DragonEmperor9480/aws_cli_manager/views/ec2"
)

func EC2_mgr() {
	reader := bufio.NewReader(os.Stdin)

	ec2view.ShowEC2Menu()

	// Show dots animation like the bash script
	for i := 0; i < 3; i++ {
		time.Sleep(500 * time.Millisecond)
		fmt.Print(utils.Blue + "." + utils.Reset)
	}
	fmt.Println()

	// Show under construction box and planned features
	fmt.Println()
	fmt.Println(utils.Yellow + "┌───────────────────────────────┐" + utils.Reset)
	fmt.Println(utils.Yellow + "│     UNDER CONSTRUCTION        │" + utils.Reset)
	fmt.Println(utils.Yellow + "│                               │" + utils.Reset)
	fmt.Println(utils.Yellow + "│  EC2 Management coming soon!  │" + utils.Reset)
	fmt.Println(utils.Yellow + "│                               │" + utils.Reset)
	fmt.Println(utils.Yellow + "└───────────────────────────────┘" + utils.Reset)
	fmt.Println()
	fmt.Println(utils.Blue + "Features planned for this module:" + utils.Reset)
	fmt.Println("• Instance management (start/stop/reboot)")
	fmt.Println("• Security group configuration")
	fmt.Println("• and so on")
	fmt.Println()
	fmt.Println(utils.Yellow + "Stay tuned for updates! " + utils.Reset)
	fmt.Println()

	fmt.Print(utils.Blue + "Press Enter to return to main menu..." + utils.Reset)
	reader.ReadString('\n')
}
