package s3

import (
	"os/exec"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func ListS3BucketsModel() string {
	utils.ShowProcessingAnimation("Listing S3 Buckets")
	cmd := exec.Command("aws", "s3", "ls")
	output, err := cmd.CombinedOutput()
	if err != nil {
		utils.StopAnimation()
		println("Error listing S3 buckets:", err.Error())
		return err.Error()
	}
	utils.StopAnimation()
	return string(output)
}
