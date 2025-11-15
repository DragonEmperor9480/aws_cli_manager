package models

import (
	"os"
	"os/exec"
	"runtime"
	"strings"
)

const Version = "PRE RELEASE EDITION"

// VersionInfo holds version and OS information
type VersionInfo struct {
	Version string `json:"version"`
	OS      string `json:"os"`
	OSName  string `json:"os_name"`
}

// GetVersion returns version and OS information
func GetVersion() VersionInfo {
	osInfo := runtime.GOOS
	osName := getOSDetail(osInfo)

	return VersionInfo{
		Version: Version,
		OS:      osInfo,
		OSName:  osName,
	}
}

func getOSDetail(osInfo string) string {
	switch osInfo {
	case "windows":
		return "Windows"
	case "darwin":
		cmd := exec.Command("sw_vers", "-productVersion")
		output, err := cmd.Output()
		if err == nil {
			versionStr := strings.TrimSpace(string(output))
			return "MacOS " + versionStr
		}
		return "MacOS"
	case "linux":
		data, err := os.ReadFile("/etc/os-release")
		if err == nil {
			lines := strings.Split(string(data), "\n")
			for _, line := range lines {
				if strings.HasPrefix(line, "PRETTY_NAME=") {
					return strings.Trim(line[12:], "\"")
				}
			}
		}
		return "Linux"
	default:
		return osInfo
	}
}
