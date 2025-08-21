package s3

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	s3model "github.com/DragonEmperor9480/aws_cli_manager/models/s3"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func S3BucketVersioningController() {
	reader := bufio.NewReader(os.Stdin)
	ListS3Buckets()

	fmt.Print("Enter the S3 bucket name: ")
	bucketName, _ := reader.ReadString('\n')
	bucketName = strings.TrimSpace(bucketName)

	if !utils.InputChecker(bucketName) {
		fmt.Println("Bucket name cannot be empty.")
		return
	}

	// Get current status
	status, err := s3model.GetBucketVersioningStatusModel(bucketName)
	if err != nil {
		fmt.Println("Error checking versioning:", err.Error())
		return
	}

	if status == "" {
		status = "Not Enabled"
	}

	fmt.Println("Current Versioning Status:", status)

	var newStatus string
	if status == "Enabled" {
		fmt.Print("Do you want to Suspend versioning? (Y/N): ")
		choice, _ := reader.ReadString('\n')
		choice = strings.TrimSpace(strings.ToUpper(choice))
		if choice == "Y" {
			newStatus = "Suspended"
		}
	} else {
		fmt.Print("Do you want to Enable versioning? (Y/N): ")
		choice, _ := reader.ReadString('\n')
		choice = strings.TrimSpace(strings.ToUpper(choice))
		if choice == "Y" {
			newStatus = "Enabled"
		}
	}

	if newStatus == "" {
		fmt.Println("No changes made.")
		return
	}

	// Apply change
	err = s3model.SetBucketVersioningModel(bucketName, newStatus)
	if err != nil {
		fmt.Println("Error setting versioning:", err.Error())
		return
	}

	fmt.Println("Bucket versioning updated to:", newStatus)
}
