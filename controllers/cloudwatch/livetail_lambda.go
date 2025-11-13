package cloudwatch

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	cloudwatch_model "github.com/DragonEmperor9480/aws_cli_manager/models/cloudwatch"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	cloudwatch_view "github.com/DragonEmperor9480/aws_cli_manager/views/cloudwatch"
	"github.com/gdamore/tcell/v2"
)

func LiveTailLambdaLogs() {
	utils.ClearScreen()
	fmt.Println(utils.Bold + utils.Cyan + "Live Tail Lambda Logs" + utils.Reset)
	fmt.Println("────────────────────────────────────")

	// Fetch Lambda functions using model
	utils.ShowProcessingAnimation("Fetching Lambda functions")
	output, err := cloudwatch_model.FetchLambdaFunctions()
	utils.StopAnimation()

	if err != nil {
		fmt.Println(utils.Red + "Error fetching Lambda functions: " + err.Error() + utils.Reset)
		return
	}

	functions := strings.Split(strings.TrimSpace(string(output)), "\n")

	// Clean up function names
	for i := range functions {
		functions[i] = strings.TrimSpace(functions[i])
	}

	if len(functions) == 0 || functions[0] == "" {
		fmt.Println(utils.Yellow + "No Lambda functions found in your account." + utils.Reset)
		return
	}

	// Display functions
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

	// Start interactive log viewer using view
	startInteractiveLogViewer(logGroupName, selectedFunction)
}

func startInteractiveLogViewer(logGroupName, functionName string) {
	// Initialize view
	viewer, err := cloudwatch_view.NewLogViewer(functionName)
	if err != nil {
		fmt.Println(utils.Red + "Error initializing viewer: " + err.Error() + utils.Reset)
		return
	}
	defer viewer.Close()

	// Start log streaming from model
	logChan := make(chan cloudwatch_model.LogEntry, 100)
	errChan := make(chan error, 1)

	go cloudwatch_model.StreamLambdaLogs(viewer.GetContext(), logGroupName, logChan, errChan)

	// Handle incoming logs
	go func() {
		for {
			select {
			case <-viewer.GetContext().Done():
				return
			case logEntry := <-logChan:
				// Convert model LogEntry to view LogEntry
				viewLogEntry := cloudwatch_view.LogEntry{
					Message: logEntry.Message,
					Color:   logEntry.Color,
				}
				viewer.AddLog(viewLogEntry)
				viewer.GetScreen().PostEvent(tcell.NewEventInterrupt(nil))
			case err := <-errChan:
				if err != nil {
					// Log error silently or handle as needed
					return
				}
			}
		}
	}()

	// Start auto-scroll
	viewer.AutoScroll()

	// Initial render
	viewer.Render()

	// Event loop
	searchMode := false
	for {
		ev := viewer.GetScreen().PollEvent()
		switch ev := ev.(type) {
		case *tcell.EventResize:
			viewer.GetScreen().Sync()
			viewer.Render()
		case *tcell.EventKey:
			if searchMode {
				// Handle search mode keys
				switch ev.Key() {
				case tcell.KeyEscape:
					viewer.ToggleSearchMode()
					searchMode = false
					viewer.Render()
				case tcell.KeyBackspace, tcell.KeyBackspace2:
					viewer.RemoveFromSearchQuery()
					viewer.Render()
				case tcell.KeyEnter:
					viewer.NextMatch()
					viewer.Render()
				case tcell.KeyRune:
					switch ev.Rune() {
					case 'w', 'W':
						viewer.PrevMatch()
						viewer.Render()
					case 's', 'S':
						viewer.NextMatch()
						viewer.Render()
					default:
						viewer.AddToSearchQuery(ev.Rune())
						viewer.Render()
					}
				}
			} else {
				// Handle normal mode keys
				switch ev.Key() {
				case tcell.KeyEscape, tcell.KeyCtrlC:
					return
				case tcell.KeyRune:
					switch ev.Rune() {
					case 'q', 'Q':
						return
					case ' ':
						viewer.TogglePause()
						viewer.Render()
					case 'r', 'R':
						viewer.ResetLogs()
						viewer.Render()
					case 'f', 'F', '/':
						viewer.ToggleSearchMode()
						searchMode = true
						viewer.Render()
					}
				case tcell.KeyUp:
					viewer.ScrollUp()
					viewer.Render()
				case tcell.KeyDown:
					viewer.ScrollDown()
					viewer.Render()
				case tcell.KeyPgUp:
					viewer.PageUp()
					viewer.Render()
				case tcell.KeyPgDn:
					viewer.PageDown()
					viewer.Render()
				}
			}
		case *tcell.EventInterrupt:
			viewer.Render()
		}
	}
}
