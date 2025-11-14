package api

import (
	"encoding/json"
	"net/http"
	"os"
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
	// Check if credentials file exists
	homeDir, err := os.UserHomeDir()
	if err != nil {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"configured": false,
			"message":    "Failed to get home directory",
		})
		return
	}

	credentialsFile := filepath.Join(homeDir, ".aws", "credentials")
	configFile := filepath.Join(homeDir, ".aws", "config")

	// Check if credentials file exists and is not empty
	credInfo, err := os.Stat(credentialsFile)
	if err != nil || credInfo.Size() == 0 {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"configured": false,
			"message":    "AWS credentials file not found",
		})
		return
	}

	// Check if config file exists
	_, err = os.Stat(configFile)
	if err != nil {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"configured": false,
			"message":    "AWS config file not found",
		})
		return
	}

	// Try to read credentials to verify they're valid format
	credContent, err := os.ReadFile(credentialsFile)
	if err != nil {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"configured": false,
			"message":    "Failed to read credentials file",
		})
		return
	}

	credStr := string(credContent)
	if !strings.Contains(credStr, "aws_access_key_id") || !strings.Contains(credStr, "aws_secret_access_key") {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"configured": false,
			"message":    "Credentials file is invalid",
		})
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"configured": true,
		"message":    "AWS credentials configured",
	})
}
