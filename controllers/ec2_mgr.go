package controllers

import (
	ec2view "github.com/DragonEmperor9480/aws_cli_manager/views/ec2"
)

func EC2_mgr() {
	// reader := bufio.NewReader(os.Stdin)

	ec2view.ShowEC2Menu()

}
