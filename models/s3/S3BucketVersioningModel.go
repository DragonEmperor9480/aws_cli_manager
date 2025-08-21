package s3

import (
	"encoding/json"
	"fmt"
	"os/exec"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

type BucketVersioning struct {
	Status string `json:"Status"`
}

// Get current bucket versioning status (Enabled, Suspended, or empty if never set)
func GetBucketVersioningStatusModel(bucketName string) (string, error) {
	utils.ShowProcessingAnimation("Checking versioning status for bucket: " + bucketName)
	cmd := exec.Command("aws", "s3api", "get-bucket-versioning", "--bucket", bucketName)
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	utils.StopAnimation()
	fmt.Println()

	var result BucketVersioning
	_ = json.Unmarshal(out, &result)

	return result.Status, nil
}

func SetBucketVersioningModel(bucketName, status string) error {
	cmd := exec.Command("aws", "s3api", "put-bucket-versioning",
		"--bucket", bucketName,
		"--versioning-configuration", "Status="+status,
	)
	_, err := cmd.Output()
	return err
}
