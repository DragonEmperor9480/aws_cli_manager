package s3

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	s3model "github.com/DragonEmperor9480/aws_cli_manager/models/s3"
)

func S3ListBucketObjectsController() {
	ListS3Buckets()
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Enter the bucket name you want to list objects from: ")
	bucketName, _ := reader.ReadString('\n')
	bucketName = strings.TrimSpace(bucketName)

	if bucketName == "" {
		fmt.Println("Error: Please enter a valid bucket name.")
		return
	}

	s3model.S3ListBucketObjects(bucketName)
}
