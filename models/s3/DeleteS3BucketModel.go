package s3

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

type ObjectVersion struct {
	Key       string `json:"Key"`
	VersionId string `json:"VersionId"`
}

type ObjectVersionsOutput struct {
	Versions      []ObjectVersion `json:"Versions"`
	DeleteMarkers []ObjectVersion `json:"DeleteMarkers"`
}

func DeleteS3BucketModel(bucketName string) error {
	// Step 0: Check if bucket has objects
	lsCmd := exec.Command("aws", "s3api", "list-objects", "--bucket", bucketName, "--output", "json")
	lsOut, _ := lsCmd.CombinedOutput()

	var objMap map[string]interface{}
	_ = json.Unmarshal(lsOut, &objMap)

	objectsExist := false
	if contents, ok := objMap["Contents"]; ok {
		if arr, ok := contents.([]interface{}); ok && len(arr) > 0 {
			objectsExist = true
		}
	}

	if objectsExist {
		// Ask user confirmation
		reader := bufio.NewReader(os.Stdin)
		fmt.Printf("Bucket '%s' contains objects. Do you still want to delete it? (y/n): ", bucketName)
		confirm, _ := reader.ReadString('\n')
		confirm = strings.TrimSpace(strings.ToLower(confirm))
		if confirm != "y" {
			fmt.Println("Operation cancelled. Bucket not deleted.")
			return nil
		}
	}

	utils.ShowProcessingAnimation("Deleting S3 bucket: " + bucketName)

	// 1. Remove all objects (non-versioned bucket)
	rmCmd := exec.Command("aws", "s3", "rm", "s3://"+bucketName, "--recursive")
	_, rmErr := rmCmd.CombinedOutput()
	if rmErr != nil {
		utils.StopAnimation()
		return fmt.Errorf("failed to empty bucket (objects deletion error)")
	}

	// 2. Remove all versions if bucket is versioned
	verCmd := exec.Command("aws", "s3api", "list-object-versions", "--bucket", bucketName, "--output", "json")
	verOut, verErr := verCmd.CombinedOutput()
	if verErr == nil {
		var versions ObjectVersionsOutput
		if err := json.Unmarshal(verOut, &versions); err == nil {
			// Delete versions
			for _, v := range versions.Versions {
				exec.Command("aws", "s3api", "delete-object",
					"--bucket", bucketName,
					"--key", v.Key,
					"--version-id", v.VersionId).Run()
			}
			// Delete markers
			for _, v := range versions.DeleteMarkers {
				exec.Command("aws", "s3api", "delete-object",
					"--bucket", bucketName,
					"--key", v.Key,
					"--version-id", v.VersionId).Run()
			}
		}
	}

	// 3. Delete bucket itself
	delCmd := exec.Command("aws", "s3api", "delete-bucket", "--bucket", bucketName)
	delOut, delErr := delCmd.CombinedOutput()
	utils.StopAnimation()
	if delErr != nil {
		return fmt.Errorf("failed to delete bucket: %s", string(delOut))
	}

	return nil
}
