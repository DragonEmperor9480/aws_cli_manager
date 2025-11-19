package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	cloudwatch_model "github.com/DragonEmperor9480/aws_cli_manager/models/cloudwatch"
	"github.com/gorilla/mux"
)

// ListLambdaFunctions lists all Lambda functions
func ListLambdaFunctions(w http.ResponseWriter, r *http.Request) {
	output, err := cloudwatch_model.FetchLambdaFunctions()
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	// Parse function names
	functions := []string{}
	lines := string(output)
	for _, line := range splitLines(lines) {
		if line != "" {
			functions = append(functions, line)
		}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"functions": functions,
	})
}

// StreamLambdaLogs streams Lambda logs using Server-Sent Events (SSE)
func StreamLambdaLogs(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	functionName := vars["function"]
	logGroupName := "/aws/lambda/" + functionName

	// Set headers for SSE
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// Create channels for log streaming
	logChan := make(chan cloudwatch_model.LogEntry, 100)
	errChan := make(chan error, 1)
	ctx, cancel := context.WithCancel(r.Context())
	defer cancel()

	// Start streaming logs
	go cloudwatch_model.StreamLambdaLogs(ctx, logGroupName, logChan, errChan)

	// Create a flusher for SSE
	flusher, ok := w.(http.Flusher)
	if !ok {
		respondError(w, http.StatusInternalServerError, "Streaming not supported")
		return
	}

	// Send initial connection message
	fmt.Fprintf(w, "data: {\"type\":\"connected\",\"function\":\"%s\"}\n\n", functionName)
	flusher.Flush()

	// Stream logs to client
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			// Send keepalive
			fmt.Fprintf(w, ": keepalive\n\n")
			flusher.Flush()
		case logEntry := <-logChan:
			// Send log entry as JSON
			data, err := json.Marshal(map[string]interface{}{
				"type":    "log",
				"message": logEntry.Message,
				"color":   logEntry.Color,
			})
			if err != nil {
				continue
			}
			fmt.Fprintf(w, "data: %s\n\n", data)
			flusher.Flush()
		case err := <-errChan:
			if err != nil {
				data, _ := json.Marshal(map[string]interface{}{
					"type":  "error",
					"error": err.Error(),
				})
				fmt.Fprintf(w, "data: %s\n\n", data)
				flusher.Flush()
				return
			}
		}
	}
}

func splitLines(s string) []string {
	result := []string{}
	current := ""
	for _, ch := range s {
		if ch == '\n' {
			result = append(result, current)
			current = ""
		} else {
			current += string(ch)
		}
	}
	if current != "" {
		result = append(result, current)
	}
	return result
}
