package s3

import (
	"os/exec"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func CreateS3BucketModel(bucketname string) {
	utils.ShowProcessingAnimation("Creating S3 bucket: " + bucketname)
	cmd := exec.Command("aws", "s3", "mb", "s3://"+bucketname)
	output, err := cmd.CombinedOutput()
	if err != nil {
		utils.StopAnimation()
		println("Error creating S3 bucket:", err.Error())
		return
	}
	utils.StopAnimation()
	println("S3 bucket created successfully:", string(output))
}
