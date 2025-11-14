package api

import (
	"encoding/json"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// ConfigureAWS configures AWS credentials
func ConfigureAWS(w http.ResponseWriter, r *http.Request) {
	var req struct {
		AccessKeyID     string `json:"access_key_id"`
		SecretAccessKey string `json:"secret_access_key"`
		Region          string `json:"region"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	if req.AccessKeyID == "" || req.SecretAccessKey == "" || req.Region == "" {
		respondError(w, http.StatusBadRequest, "All fields are required")
		return
	}

	// Create AWS credentials directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to get home directory")
		return
	}

	awsDir := filepath.Join(homeDir, ".aws")
	if err := os.MkdirAll(awsDir, 0700); err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to create .aws directory")
		return
	}

	// Write credentials file
	credentialsFile := filepath.Join(awsDir, "credentials")
	credentialsContent := `[default]
aws_access_key_id = ` + req.AccessKeyID + `
aws_secret_access_key = ` + req.SecretAccessKey + `
`

	if err := os.WriteFile(credentialsFile, []byte(credentialsContent), 0600); err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to write credentials file")
		return
	}

	// Write config file
	configFile := filepath.Join(awsDir, "config")
	configContent := `[default]
region = ` + req.Region + `
output = json
`

	if err := os.WriteFile(configFile, []byte(configContent), 0600); err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to write config file")
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{"message": "AWS credentials configured successfully"})
}

// GetAWSConfig gets current AWS configuration
func GetAWSConfig(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("aws", "configure", "list")
	output, err := cmd.CombinedOutput()
	if err != nil {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"configured": false,
			"message":    "AWS CLI not configured",
		})
		return
	}

	// Check if credentials are actually configured
	outputStr := string(output)
	if strings.Contains(outputStr, "not set") || strings.Contains(outputStr, "<not set>") {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"configured": false,
			"message":    "AWS credentials not configured",
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"configured": true,
		"output":     outputStr,
	})
}
