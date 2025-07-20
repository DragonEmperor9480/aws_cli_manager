package user

import (
	"os/exec"
	"strings"
)

func UserExistsOrNotModel(username string) bool {
	checkCmd := exec.Command("aws", "iam", "get-user", "--user-name", username)
    output, _ := checkCmd.CombinedOutput()
    if strings.Contains(string(output), "NoSuchEntity") {
        return false
    }
    return true
}			

