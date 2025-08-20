package s3

import (
	"os/exec"
	"strings"
	views "github.com/DragonEmperor9480/aws_cli_manager/views/s3"
)

func S3ListBucketObjects(bucketName string) {
	cmd := exec.Command("aws", "s3", "ls", "s3://"+bucketName, "--recursive")
	output, err := cmd.CombinedOutput()
	outStr := strings.TrimSpace(string(output))

	// Handle errors
	if err != nil {
		if strings.Contains(outStr, "NoSuchBucket") {
			views.PrintError("The specified bucket '" + bucketName + "' does not exist!")
		} else {
			views.PrintError("Error fetching objects: " + err.Error())
		}
		return
	}

	// Empty bucket
	if outStr == "" {
		views.PrintWarning("No objects found in bucket '" + bucketName + "'.")
		return
	}

	// Send parsed lines to view
	lines := strings.Split(outStr, "\n")
	views.PrintS3Objects(lines)
}
