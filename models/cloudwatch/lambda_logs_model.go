package cloudwatch

import (
	"context"
	"regexp"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatchlogs"
	"github.com/aws/aws-sdk-go-v2/service/lambda"
)

// LogEntry represents a parsed log entry with color information
type LogEntry struct {
	Message string
	Color   string
}

// FetchLambdaFunctions retrieves all Lambda function names using AWS SDK
func FetchLambdaFunctions() ([]byte, error) {
	ctx := context.TODO()
	result, err := utils.LambdaClient.ListFunctions(ctx, &lambda.ListFunctionsInput{})
	if err != nil {
		return nil, err
	}

	// Format output to match old text format
	var output strings.Builder
	for _, fn := range result.Functions {
		output.WriteString(aws.ToString(fn.FunctionName))
		output.WriteString("\n")
	}

	return []byte(output.String()), nil
}

// ParseLogLine extracts the actual log message from CloudWatch format
func ParseLogLine(line string) LogEntry {
	// Regex to match timestamp and stream ID at the beginning
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

// StreamLambdaLogs streams logs from a Lambda function log group using AWS SDK
func StreamLambdaLogs(ctx context.Context, logGroupName string, logChan chan<- LogEntry, errChan chan<- error) {
	// Use FilterLogEvents with follow-like behavior
	input := &cloudwatchlogs.FilterLogEventsInput{
		LogGroupName: aws.String(logGroupName),
		StartTime:    aws.Int64(0), // Start from beginning or use time.Now().Unix() * 1000 for recent
	}

	// Initial fetch
	result, err := utils.LogsClient.FilterLogEvents(ctx, input)
	if err != nil {
		errChan <- err
		return
	}

	// Send initial events
	for _, event := range result.Events {
		message := aws.ToString(event.Message)
		if message == "" {
			continue
		}
		select {
		case <-ctx.Done():
			return
		case logChan <- ParseLogLine(message):
		}
	}

	// Continue polling for new events
	nextToken := result.NextToken
	for {
		select {
		case <-ctx.Done():
			return
		default:
			if nextToken != nil {
				input.NextToken = nextToken
			}

			result, err := utils.LogsClient.FilterLogEvents(ctx, input)
			if err != nil {
				continue // Ignore errors and keep trying
			}

			for _, event := range result.Events {
				message := aws.ToString(event.Message)
				if message == "" {
					continue
				}
				select {
				case <-ctx.Done():
					return
				case logChan <- ParseLogLine(message):
				}
			}

			nextToken = result.NextToken
		}
	}
}
