package views

import (
	"fmt"

	"github.com/jedib0t/go-pretty/v6/table"
	"github.com/jedib0t/go-pretty/v6/text"
)

// TableConfig holds configuration for rendering a table
type TableConfig struct {
	Headers      []string
	Rows         [][]string
	ColumnColors []text.Color // Optional: custom colors for each column
}

// RenderTable renders a beautiful, consistent table across the application
func RenderTable(config TableConfig) {
	t := table.NewWriter()

	// Add serial number to headers
	headers := append([]interface{}{"#"}, interfaceSlice(config.Headers)...)
	t.AppendHeader(table.Row(headers))

	// Add data rows with serial numbers
	for i, row := range config.Rows {
		rowData := append([]interface{}{i + 1}, interfaceSlice(row)...)
		t.AppendRow(table.Row(rowData))
	}

	// Apply consistent styling
	t.SetStyle(table.StyleRounded)
	t.Style().Options.DrawBorder = true
	t.Style().Options.SeparateColumns = true
	t.Style().Options.SeparateHeader = true
	t.Style().Options.SeparateRows = true

	// Color headers (cyan and bold)
	t.Style().Color.Header = text.Colors{text.FgCyan, text.Bold}

	// Make borders cyan
	t.Style().Color.Border = text.Colors{text.FgCyan}
	t.Style().Color.Separator = text.Colors{text.FgCyan}

	// Configure columns
	columnConfigs := []table.ColumnConfig{
		// Serial number column - blue bold, center-aligned
		{
			Number:       1,
			Colors:       text.Colors{text.FgBlue, text.Bold},
			ColorsHeader: text.Colors{text.FgCyan, text.Bold},
			Align:        text.AlignCenter,
			AlignHeader:  text.AlignCenter,
		},
	}

	// Default color scheme for data columns
	defaultColors := []text.Color{
		text.FgGreen,   // Column 1 (usually name/identifier)
		text.FgYellow,  // Column 2 (usually date/status)
		text.FgMagenta, // Column 3 (usually time/info)
		text.FgCyan,    // Column 4
		text.FgWhite,   // Column 5
		text.FgBlue,    // Column 6
	}

	// Use custom colors if provided, otherwise use defaults
	colors := config.ColumnColors
	if colors == nil {
		colors = defaultColors
	}

	// Add column configs for data columns
	for i := 0; i < len(config.Headers); i++ {
		colorIndex := i % len(colors)
		columnConfigs = append(columnConfigs, table.ColumnConfig{
			Number:       i + 2, // +2 because serial number is column 1
			Colors:       text.Colors{colors[colorIndex]},
			ColorsHeader: text.Colors{text.FgCyan, text.Bold},
		})
	}

	t.SetColumnConfigs(columnConfigs)

	fmt.Println()
	fmt.Println(t.Render())
	fmt.Println()
}

// interfaceSlice converts a string slice to interface slice
func interfaceSlice(slice []string) []interface{} {
	result := make([]interface{}, len(slice))
	for i, v := range slice {
		result[i] = v
	}
	return result
}

// RenderTableWithoutSerial renders a table without serial numbers (useful for side-by-side displays)
func RenderTableWithoutSerial(config TableConfig) {
	t := table.NewWriter()

	// Add headers without serial number
	t.AppendHeader(table.Row(interfaceSlice(config.Headers)))

	// Add data rows without serial numbers
	for _, row := range config.Rows {
		t.AppendRow(table.Row(interfaceSlice(row)))
	}

	// Apply consistent styling
	t.SetStyle(table.StyleRounded)
	t.Style().Options.DrawBorder = true
	t.Style().Options.SeparateColumns = true
	t.Style().Options.SeparateHeader = true
	t.Style().Options.SeparateRows = true

	// Color headers (cyan and bold)
	t.Style().Color.Header = text.Colors{text.FgCyan, text.Bold}

	// Make borders cyan
	t.Style().Color.Border = text.Colors{text.FgCyan}
	t.Style().Color.Separator = text.Colors{text.FgCyan}

	// Default color scheme for data columns
	defaultColors := []text.Color{
		text.FgGreen,   // Column 1
		text.FgYellow,  // Column 2
		text.FgMagenta, // Column 3
		text.FgCyan,    // Column 4
		text.FgWhite,   // Column 5
		text.FgBlue,    // Column 6
	}

	// Use custom colors if provided, otherwise use defaults
	colors := config.ColumnColors
	if colors == nil {
		colors = defaultColors
	}

	// Configure columns
	var columnConfigs []table.ColumnConfig
	for i := 0; i < len(config.Headers); i++ {
		colorIndex := i % len(colors)
		columnConfigs = append(columnConfigs, table.ColumnConfig{
			Number:       i + 1,
			Colors:       text.Colors{colors[colorIndex]},
			ColorsHeader: text.Colors{text.FgCyan, text.Bold},
		})
	}

	t.SetColumnConfigs(columnConfigs)

	fmt.Println()
	fmt.Println(t.Render())
	fmt.Println()
}
