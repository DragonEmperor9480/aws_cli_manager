package controllers

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	s3controller "github.com/DragonEmperor9480/aws_cli_manager/controllers/s3"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	s3view "github.com/DragonEmperor9480/aws_cli_manager/views/s3"
)

func S3_mgr() {
	reader := bufio.NewReader(os.Stdin)

	for {
		s3view.ShowS3Menu()

		fmt.Print("Enter your choice: ")
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		switch input {
		case "1":
			s3controller.CreateS3Bucket()
			utils.Bk()
		case "2":
			s3controller.ListS3Buckets()
			utils.Bk()
		case "3":
			s3controller.DeleteS3Bucket()
			utils.Bk()
		case "4":
			s3controller.S3ListBucketObjectsController()
			utils.Bk()
		case "5":
			s3controller.S3BucketMFADeleteController()
			utils.Bk()
		case "6":
			// Back to main menu
			fmt.Println("Returning to Main Menu...")
			return
		default:
			fmt.Println(utils.Red + "Invalid Input. Please try again." + utils.Reset)
			utils.Bk()
		}
	}
}
