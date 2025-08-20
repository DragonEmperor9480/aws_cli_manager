package s3

import (
	"fmt"
	"os/exec"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

// Get current versioning + MFA status
func GetBucketVersioning(bucket string) string {
	cmd := exec.Command("aws", "s3api", "get-bucket-versioning", "--bucket", bucket)
	output, _ := cmd.CombinedOutput()
	return string(output)
}

// Update MFA Delete config
func UpdateBucketMFADelete(bucket, securityARN, mfaCode string, enable bool) {
	utils.ShowProcessingAnimation("Updating MFA Delete setting...")

	var config string
	actionMsg := "disabled"
	if enable {
		config = "Status=Enabled,MFADelete=Enabled"
		actionMsg = "enabled"
	} else {
		config = "Status=Enabled,MFADelete=Disabled"
	}

	cmd := exec.Command("aws", "s3api", "put-bucket-versioning",
		"--bucket", bucket,
		"--versioning-configuration", config,
		"--mfa", fmt.Sprintf("%s %s", securityARN, mfaCode),
	)

	output, err := cmd.CombinedOutput()
	utils.StopAnimation()

	if err != nil {
		fmt.Println(utils.Red + "Failed to update MFA Delete:" + utils.Reset)
		fmt.Println(string(output))
	} else {
		fmt.Println(utils.Green + "MFA Delete successfully " + actionMsg + " for bucket '" + bucket + "'." + utils.Reset)
	}
}
