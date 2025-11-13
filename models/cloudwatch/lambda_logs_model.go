package cloudwatch

import (
	"bufio"
	"context"
	"os/exec"
	"regexp"
	"strings"
)

// FetchLambdaFunctions retrieves all Lambda function names
func FetchLambdaFunctions() ([]byte, error) {
	cmd := exec.Command("aws", "lambda", "list-functions", "--query", "Functions[*].[FunctionName]", "--output", "text")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}
	return output, nil
}

// LogEntry represents a parsed log entry with color information
type LogEntry struct {
	Message string
	Color   string
}

// ParseLogLine extracts the actual log message from CloudWatch format
// Format: TIMESTAMP STREAM_ID MESSAGE
func ParseLogLine(line string) LogEntry {
	// Regex to match timestamp and stream ID at the beginning
	// Example: 2025-11-13T04:11:50.643000+00:00 2025/11/13/[$LATEST]b2cd0cdf48ca47c1aa7e7833aab60a59
	re := regexp.MustCompile(`^\S+\s+\S+\s+(.*)$`)
	matches := re.FindStringSubmatch(line)

	var message string
	if len(matches) > 1 {
		message = matches[1]
	} else {
		message = line
	}

	// Determine color based on log content
	color := determineLogColor(message)

	return LogEntry{
		Message: message,
		Color:   color,
	}
}

// determineLogColor assigns color based on log level or content
func determineLogColor(message string) string {
	msgLower := strings.ToLower(message)

	// Error patterns
	if strings.Contains(msgLower, "error") || strings.Contains(msgLower, "exception") ||
		strings.Contains(msgLower, "fatal") || strings.Contains(msgLower, "fail") {
		return "red"
	}

	// Warning patterns
	if strings.Contains(msgLower, "warn") || strings.Contains(msgLower, "warning") {
		return "yellow"
	}

	// Info/Success patterns
	if strings.Contains(msgLower, "success") || strings.Contains(msgLower, "complete") ||
		strings.Contains(msgLower, "done") {
		return "green"
	}

	// Debug patterns
	if strings.Contains(msgLower, "debug") || strings.Contains(msgLower, "trace") {
		return "cyan"
	}

	// START/END/REPORT patterns (Lambda specific)
	if strings.HasPrefix(message, "START") || strings.HasPrefix(message, "END") ||
		strings.HasPrefix(message, "REPORT") {
		return "blue"
	}

	// Default color
	return "white"
}

// StreamLambdaLogs streams logs from a Lambda function log group
func StreamLambdaLogs(ctx context.Context, logGroupName string, logChan chan<- LogEntry, errChan chan<- error) {
	cmd := exec.CommandContext(ctx, "aws", "logs", "tail", logGroupName, "--follow")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		errChan <- err
		return
	}

	if err := cmd.Start(); err != nil {
		errChan <- err
		return
	}

	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		select {
		case <-ctx.Done():
			return
		case logChan <- ParseLogLine(scanner.Text()):
		}
	}

	if err := scanner.Err(); err != nil {
		errChan <- err
	}

	cmd.Wait()
}
