package utils

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

func GetVersion() {
	const version = "Pre Release Edition"
	fmt.Println(Bold + Magenta + "Aws Manager" + Reset)
	fmt.Println("Version:", version)

	osInfo := runtime.GOOS
	detail := ""

	switch osInfo {
	case "windows":
		detail = "Windows"
	case "darwin":
		// Get MacOS version using 'sw_vers -productVersion'
		cmd := exec.Command("sw_vers", "-productVersion")
		output, err := cmd.Output()
		if err == nil {
			versionStr := strings.TrimSpace(string(output))
			detail = "MacOS " + versionStr
		} else {
			detail = "MacOS"
		}
	case "linux":
		data, err := os.ReadFile("/etc/os-release")
		if err == nil {
			lines := strings.Split(string(data), "\n")
			for _, line := range lines {
				if strings.HasPrefix(line, "PRETTY_NAME=") {
					detail = strings.Trim(line[12:], "\"")
					break
				}
			}
			if detail == "" {
				detail = "Linux"
			}
		} else {
			detail = "Linux"
		}
	default:
		detail = osInfo
	}

	fmt.Println("Running on:", detail)
}
