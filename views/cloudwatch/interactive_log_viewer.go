package cloudwatch

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/gdamore/tcell/v2"
)

type LogEntry struct {
	Message string
	Color   string
}

type LogViewer struct {
	screen         tcell.Screen
	logs           []LogEntry
	logsMutex      sync.RWMutex
	scrollPos      int
	paused         bool
	functionName   string
	ctx            context.Context
	cancel         context.CancelFunc
	searchMode     bool
	searchQuery    string
	searchMatches  []int // Line indices that match the search
	currentMatch   int   // Current match index in searchMatches
	autoScrolling  bool  // Track if we should auto-scroll
}

func NewLogViewer(functionName string) (*LogViewer, error) {
	screen, err := tcell.NewScreen()
	if err != nil {
		return nil, err
	}
	if err := screen.Init(); err != nil {
		return nil, err
	}

	screen.SetStyle(tcell.StyleDefault.Background(tcell.ColorBlack).Foreground(tcell.ColorWhite))
	screen.Clear()

	ctx, cancel := context.WithCancel(context.Background())

	return &LogViewer{
		screen:        screen,
		logs:          []LogEntry{},
		scrollPos:     0,
		paused:        false,
		functionName:  functionName,
		ctx:           ctx,
		cancel:        cancel,
		searchMode:    false,
		searchQuery:   "",
		searchMatches: []int{},
		currentMatch:  -1,
		autoScrolling: true,
	}, nil
}

func (lv *LogViewer) Close() {
	lv.cancel()
	lv.screen.Fini()
}

func (lv *LogViewer) AddLog(log LogEntry) {
	if !lv.paused {
		lv.logsMutex.Lock()
		lv.logs = append(lv.logs, log)
		lv.logsMutex.Unlock()
	}
}

func (lv *LogViewer) ResetLogs() {
	lv.logsMutex.Lock()
	lv.logs = []LogEntry{}
	lv.scrollPos = 0
	lv.logsMutex.Unlock()
}

func (lv *LogViewer) getColorFromString(colorName string) tcell.Color {
	switch colorName {
	case "red":
		return tcell.ColorRed
	case "yellow":
		return tcell.ColorYellow
	case "green":
		return tcell.ColorGreen
	case "cyan":
		return tcell.ColorAqua
	case "blue":
		return tcell.ColorBlue
	case "magenta":
		return tcell.ColorPurple
	default:
		return tcell.ColorWhite
	}
}

func (lv *LogViewer) TogglePause() {
	lv.paused = !lv.paused
}

func (lv *LogViewer) ToggleSearchMode() {
	lv.searchMode = !lv.searchMode
	if !lv.searchMode {
		lv.searchQuery = ""
		lv.searchMatches = []int{}
		lv.currentMatch = -1
	}
}

func (lv *LogViewer) AddToSearchQuery(ch rune) {
	lv.searchQuery += string(ch)
	lv.updateSearchMatches()
}

func (lv *LogViewer) RemoveFromSearchQuery() {
	if len(lv.searchQuery) > 0 {
		lv.searchQuery = lv.searchQuery[:len(lv.searchQuery)-1]
		lv.updateSearchMatches()
	}
}

func (lv *LogViewer) updateSearchMatches() {
	lv.logsMutex.RLock()
	defer lv.logsMutex.RUnlock()

	lv.searchMatches = []int{}
	if lv.searchQuery == "" {
		lv.currentMatch = -1
		return
	}

	query := strings.ToLower(lv.searchQuery)
	for i, log := range lv.logs {
		if strings.Contains(strings.ToLower(log.Message), query) {
			lv.searchMatches = append(lv.searchMatches, i)
		}
	}

	if len(lv.searchMatches) > 0 {
		lv.currentMatch = 0
	} else {
		lv.currentMatch = -1
	}
}

func (lv *LogViewer) NextMatch() {
	if len(lv.searchMatches) == 0 {
		return
	}
	lv.currentMatch = (lv.currentMatch + 1) % len(lv.searchMatches)
	lv.scrollToMatch()
}

func (lv *LogViewer) PrevMatch() {
	if len(lv.searchMatches) == 0 {
		return
	}
	lv.currentMatch--
	if lv.currentMatch < 0 {
		lv.currentMatch = len(lv.searchMatches) - 1
	}
	lv.scrollToMatch()
}

func (lv *LogViewer) scrollToMatch() {
	if lv.currentMatch < 0 || lv.currentMatch >= len(lv.searchMatches) {
		return
	}
	matchLine := lv.searchMatches[lv.currentMatch]
	_, height := lv.screen.Size()
	contentHeight := height - 3 // Account for header, status bar, and search bar

	// Center the match in the viewport
	lv.scrollPos = matchLine - contentHeight/2
	if lv.scrollPos < 0 {
		lv.scrollPos = 0
	}
	
	lv.logsMutex.RLock()
	maxScroll := len(lv.logs) - contentHeight
	lv.logsMutex.RUnlock()
	
	if lv.scrollPos > maxScroll && maxScroll > 0 {
		lv.scrollPos = maxScroll
	}
}

func (lv *LogViewer) ScrollUp() {
	if lv.scrollPos > 0 {
		lv.scrollPos--
		lv.autoScrolling = false // Disable auto-scroll when user scrolls up
	}
}

func (lv *LogViewer) ScrollDown() {
	lv.logsMutex.RLock()
	_, height := lv.screen.Size()
	contentHeight := height - 2
	if lv.searchMode {
		contentHeight = height - 3
	}
	
	// Check if we're at the bottom after scrolling down
	atBottom := lv.scrollPos >= len(lv.logs)-contentHeight
	
	if lv.scrollPos < len(lv.logs)-contentHeight {
		lv.scrollPos++
	}
	
	// Re-enable auto-scroll if we scrolled to the bottom
	if lv.scrollPos >= len(lv.logs)-contentHeight || atBottom {
		lv.autoScrolling = true
	}
	lv.logsMutex.RUnlock()
}

func (lv *LogViewer) PageUp() {
	_, height := lv.screen.Size()
	lv.scrollPos -= height - 2
	if lv.scrollPos < 0 {
		lv.scrollPos = 0
	}
	lv.autoScrolling = false // Disable auto-scroll when user pages up
}

func (lv *LogViewer) PageDown() {
	lv.logsMutex.RLock()
	_, height := lv.screen.Size()
	contentHeight := height - 2
	if lv.searchMode {
		contentHeight = height - 3
	}
	
	lv.scrollPos += contentHeight
	if lv.scrollPos > len(lv.logs)-contentHeight {
		lv.scrollPos = len(lv.logs) - contentHeight
	}
	if lv.scrollPos < 0 {
		lv.scrollPos = 0
	}
	
	// Re-enable auto-scroll if we're at the bottom
	if lv.scrollPos >= len(lv.logs)-contentHeight {
		lv.autoScrolling = true
	}
	lv.logsMutex.RUnlock()
}

func (lv *LogViewer) Render() {
	lv.screen.Clear()
	width, height := lv.screen.Size()

	// Header
	headerStyle := tcell.StyleDefault.Background(tcell.ColorDarkBlue).Foreground(tcell.ColorWhite).Bold(true)
	header := fmt.Sprintf(" Live Tail: %s ", lv.functionName)
	for i, ch := range header {
		lv.screen.SetContent(i, 0, ch, nil, headerStyle)
	}
	for i := len(header); i < width; i++ {
		lv.screen.SetContent(i, 0, ' ', nil, headerStyle)
	}

	// Search bar (if in search mode)
	searchBarY := height - 2
	if lv.searchMode {
		searchStyle := tcell.StyleDefault.Background(tcell.ColorDarkCyan).Foreground(tcell.ColorWhite)
		matchInfo := ""
		if len(lv.searchMatches) > 0 {
			matchInfo = fmt.Sprintf(" [%d/%d]", lv.currentMatch+1, len(lv.searchMatches))
		}
		searchText := fmt.Sprintf(" Search: %s%s | W: Prev | S: Next | ESC: Exit Search ", lv.searchQuery, matchInfo)
		for i := 0; i < width && i < len(searchText); i++ {
			lv.screen.SetContent(i, searchBarY, rune(searchText[i]), nil, searchStyle)
		}
		for i := len(searchText); i < width; i++ {
			lv.screen.SetContent(i, searchBarY, ' ', nil, searchStyle)
		}
	}

	// Status bar
	statusY := height - 1
	statusStyle := tcell.StyleDefault.Background(tcell.ColorDarkGreen).Foreground(tcell.ColorWhite)
	if lv.paused {
		statusStyle = tcell.StyleDefault.Background(tcell.ColorDarkRed).Foreground(tcell.ColorWhite)
	}
	
	scrollStatus := "AUTO"
	if !lv.autoScrolling {
		scrollStatus = "MANUAL"
	}
	
	status := fmt.Sprintf(" [%s|%s] | Logs: %d | ↑↓: Scroll | SPACE: Pause | F: Search | R: Reset | Q: Quit ",
		map[bool]string{true: "PAUSED", false: "LIVE"}[lv.paused], scrollStatus, len(lv.logs))
	for i := 0; i < width && i < len(status); i++ {
		lv.screen.SetContent(i, statusY, rune(status[i]), nil, statusStyle)
	}
	for i := len(status); i < width; i++ {
		lv.screen.SetContent(i, statusY, ' ', nil, statusStyle)
	}

	// Log content
	lv.logsMutex.RLock()
	defer lv.logsMutex.RUnlock()

	contentHeight := height - 2
	if lv.searchMode {
		contentHeight = height - 3
	}
	startIdx := lv.scrollPos
	endIdx := lv.scrollPos + contentHeight

	if endIdx > len(lv.logs) {
		endIdx = len(lv.logs)
	}
	if startIdx > len(lv.logs)-contentHeight && len(lv.logs) > contentHeight {
		startIdx = len(lv.logs) - contentHeight
		lv.scrollPos = startIdx
	}
	if startIdx < 0 {
		startIdx = 0
		lv.scrollPos = 0
	}

	for i := startIdx; i < endIdx; i++ {
		logEntry := lv.logs[i]
		color := lv.getColorFromString(logEntry.Color)
		
		y := 1 + (i - startIdx)
		x := 0
		
		// Check if this line matches search and highlight
		if lv.searchQuery != "" && strings.Contains(strings.ToLower(logEntry.Message), strings.ToLower(lv.searchQuery)) {
			lv.renderHighlightedLine(logEntry.Message, x, y, width, color, i)
		} else {
			logStyle := tcell.StyleDefault.Background(tcell.ColorBlack).Foreground(color)
			for _, ch := range logEntry.Message {
				if x >= width {
					break
				}
				lv.screen.SetContent(x, y, ch, nil, logStyle)
				x++
			}
		}
	}

	lv.screen.Show()
}

func (lv *LogViewer) renderHighlightedLine(message string, startX, y, width int, color tcell.Color, lineIdx int) {
	normalStyle := tcell.StyleDefault.Background(tcell.ColorBlack).Foreground(color)
	
	// Check if this is the current match
	isCurrentMatch := false
	for idx, matchLine := range lv.searchMatches {
		if matchLine == lineIdx && idx == lv.currentMatch {
			isCurrentMatch = true
			break
		}
	}
	
	var highlightStyle tcell.Style
	if isCurrentMatch {
		// Current match: bright yellow background
		highlightStyle = tcell.StyleDefault.Background(tcell.ColorYellow).Foreground(tcell.ColorBlack).Bold(true)
	} else {
		// Other matches: darker yellow background
		highlightStyle = tcell.StyleDefault.Background(tcell.ColorOlive).Foreground(tcell.ColorWhite)
	}

	x := startX
	messageLower := strings.ToLower(message)
	queryLower := strings.ToLower(lv.searchQuery)
	
	i := 0
	for i < len(message) {
		if x >= width {
			break
		}

		// Check if we're at the start of a match
		if strings.HasPrefix(messageLower[i:], queryLower) {
			// Highlight the matched portion
			for j := 0; j < len(lv.searchQuery) && x < width && i < len(message); j++ {
				lv.screen.SetContent(x, y, rune(message[i]), nil, highlightStyle)
				x++
				i++
			}
		} else {
			// Normal character
			lv.screen.SetContent(x, y, rune(message[i]), nil, normalStyle)
			x++
			i++
		}
	}
}

func (lv *LogViewer) AutoScroll() {
	go func() {
		ticker := time.NewTicker(100 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-lv.ctx.Done():
				return
			case <-ticker.C:
				if !lv.paused && lv.autoScrolling {
					lv.logsMutex.RLock()
					_, height := lv.screen.Size()
					contentHeight := height - 2
					if lv.searchMode {
						contentHeight = height - 3
					}
					if len(lv.logs) > contentHeight {
						lv.scrollPos = len(lv.logs) - contentHeight
					}
					lv.logsMutex.RUnlock()
					lv.screen.PostEvent(tcell.NewEventInterrupt(nil))
				}
			}
		}
	}()
}

func (lv *LogViewer) GetContext() context.Context {
	return lv.ctx
}

func (lv *LogViewer) GetScreen() tcell.Screen {
	return lv.screen
}
