package s3

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// S3BrowserController is the main entry point for the S3 file browser
func S3BrowserController() {
	// List buckets first
	ListS3Buckets()

	// Ask user to select a bucket
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("\nEnter bucket name to browse: ")
	bucketName, _ := reader.ReadString('\n')
	bucketName = strings.TrimSpace(bucketName)

	if bucketName == "" {
		fmt.Println("Error: Please enter a valid bucket name.")
		return
	}

	// Launch TUI browser
	browser, err := NewS3Browser(bucketName)
	if err != nil {
		fmt.Printf("Failed to initialize browser: %v\n", err)
		return
	}

	if err := browser.Run(); err != nil {
		fmt.Printf("Browser error: %v\n", err)
	}
}
