package s3

import (
	"context"
	"fmt"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	views "github.com/DragonEmperor9480/aws_cli_manager/views/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

func S3ListBucketObjects(bucketName string) {
	client := utils.GetS3Client()
	ctx := context.TODO()

	input := &s3.ListObjectsV2Input{
		Bucket: &bucketName,
	}

	result, err := client.ListObjectsV2(ctx, input)

	// Handle errors
	if err != nil {
		if strings.Contains(err.Error(), "NoSuchBucket") {
			views.PrintError("The specified bucket '" + bucketName + "' does not exist!")
		} else {
			views.PrintError("Error fetching objects: " + err.Error())
		}
		return
	}

	// Empty bucket
	if len(result.Contents) == 0 {
		views.PrintWarning("No objects found in bucket '" + bucketName + "'.")
		return
	}

	// Format output to match AWS CLI format
	var lines []string
	for _, obj := range result.Contents {
		lastModified := ""
		size := int64(0)
		key := ""

		if obj.LastModified != nil {
			lastModified = obj.LastModified.Format("2006-01-02 15:04:05")
		}
		if obj.Size != nil {
			size = *obj.Size
		}
		if obj.Key != nil {
			key = *obj.Key
		}

		line := fmt.Sprintf("%s %10d %s", lastModified, size, key)
		lines = append(lines, line)
	}

	// Send parsed lines to view
	views.PrintS3Objects(lines)
}
