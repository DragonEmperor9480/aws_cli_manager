package cloudwatch

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func LiveTailLambdaLogs() {
	utils.ClearScreen()
	fmt.Println(utils.Bold + utils.Cyan + "Live Tail Lambda Logs" + utils.Reset)
	fmt.Println("────────────────────────────────────")

	// List Lambda functions
	utils.ShowProcessingAnimation("Fetching Lambda functions")
	listCmd := exec.Command("aws", "lambda", "list-functions", "--query", "Functions[*].[FunctionName]", "--output", "text")
	output, err := listCmd.CombinedOutput()
	utils.StopAnimation()

	if err != nil {
		fmt.Println(utils.Red + "Error fetching Lambda functions: " + err.Error() + utils.Reset)
		return
	}

	functions := strings.Split(strings.TrimSpace(string(output)), "\n")
	
	//Add a for loop to trim the function names
	for i := range functions {
		functions[i] = strings.TrimSpace(functions[i])
	}
	
	if len(functions) == 0 || functions[0] == "" {
		fmt.Println(utils.Yellow + "No Lambda functions found in your account." + utils.Reset)
		return
	}

	// Display functions with serial numbers
	fmt.Println()
	fmt.Println(utils.Bold + "Available Lambda Functions:" + utils.Reset)
	fmt.Println("────────────────────────────────────")
	for i, fn := range functions {
		fmt.Printf(utils.Blue+"[%d]"+utils.Reset+" %s\n", i+1, fn)
	}
	fmt.Println("────────────────────────────────────")

	// Get user selection
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("\nEnter function number (or 'q' to quit): ")
	input, _ := reader.ReadString('\n')
	input = strings.TrimSpace(input)

	if input == "q" || input == "Q" {
		return
	}

	var selection int
	_, err = fmt.Sscanf(input, "%d", &selection)
	if err != nil || selection < 1 || selection > len(functions) {
		fmt.Println(utils.Red + "Invalid selection." + utils.Reset)
		return
	}

	selectedFunction := strings.TrimSpace(functions[selection-1])
	logGroupName := "/aws/lambda/" + selectedFunction

	fmt.Println()
	fmt.Println(utils.Green + "Starting live tail for: " + selectedFunction + utils.Reset)
	fmt.Println(utils.Yellow + "Press Ctrl+C to stop..." + utils.Reset)
	fmt.Println("────────────────────────────────────")

	// Start live tail
	tailCmd := exec.Command("aws", "logs", "tail", logGroupName, "--follow")
	tailCmd.Stdout = os.Stdout
	tailCmd.Stderr = os.Stderr
	tailCmd.Stdin = os.Stdin

	err = tailCmd.Run()
	if err != nil {
		fmt.Println()
		fmt.Println(utils.Red + "Error during live tail: " + err.Error() + utils.Reset)
	}
}
