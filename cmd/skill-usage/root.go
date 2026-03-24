// Usage: skill-usage [--period day|week|month|all] [--limit N] [--json]
//        skill-usage suggest [--period day|week|month|all]
// Analyzes skill invocation logs and renders usage charts or suggestions.
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/drn/dots/pkg/jsonutil"
	"github.com/drn/dots/pkg/path"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

// logPath is the JSONL log file, overridable for testing.
var logPath = path.FromDots("sys/skill-usage.jsonl")

// skillsDir is the directory containing installed skills, overridable for testing.
var skillsDir = path.FromHome(".claude/skills")

// entry represents a single skill invocation log line.
type entry struct {
	TS        string `json:"ts"`
	Skill     string `json:"skill"`
	SessionID string `json:"session_id"`
	CWD       string `json:"cwd"`
}

// skillCount pairs a skill name with its invocation count.
type skillCount struct {
	Name  string `json:"name"`
	Count int    `json:"count"`
}

func main() {
	var period string
	var limit int
	var asJSON bool

	root := &cobra.Command{
		Use:   "skill-usage",
		Short: "Show skill usage statistics",
		Run: func(_ *cobra.Command, _ []string) {
			entries := loadEntries(logPath, cutoffForPeriod(period))
			counts := countBySkill(entries)
			if asJSON {
				jsonutil.Print(sortedCounts(counts))
				return
			}
			if len(counts) == 0 {
				fmt.Printf("No skill usage found for the past %s.\n", period)
				return
			}
			renderChart(counts, limit, period)
		},
	}

	root.PersistentFlags().StringVarP(&period, "period", "p", "week", "Time period: day, week, month, all")

	root.Flags().IntVarP(&limit, "limit", "l", 20, "Max skills to show")
	root.Flags().BoolVar(&asJSON, "json", false, "Output raw JSON")

	suggest := &cobra.Command{
		Use:   "suggest",
		Short: "Suggest skills to remove or highlight high-leverage skills",
		Run: func(_ *cobra.Command, _ []string) {
			entries := loadEntries(logPath, cutoffForPeriod(period))
			counts := countBySkill(entries)
			allSkills := discoverSkills(skillsDir)
			if asJSON {
				jsonutil.Print(buildSuggestion(counts, allSkills))
				return
			}
			suggestMode(counts, allSkills, period)
		},
	}
	suggest.Flags().BoolVar(&asJSON, "json", false, "Output raw JSON")

	root.AddCommand(suggest)

	if err := root.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

// cutoffForPeriod returns the cutoff time for filtering entries.
func cutoffForPeriod(period string) time.Time {
	now := time.Now()
	switch period {
	case "day":
		return now.Add(-24 * time.Hour)
	case "week":
		return now.Add(-7 * 24 * time.Hour)
	case "month":
		return now.Add(-30 * 24 * time.Hour)
	case "all":
		return time.Time{}
	default:
		return now.Add(-7 * 24 * time.Hour)
	}
}

// loadEntries reads the JSONL file and returns entries after the cutoff time.
func loadEntries(logFile string, cutoff time.Time) []entry {
	f, err := os.Open(logFile)
	if err != nil {
		return nil
	}
	defer f.Close()

	var entries []entry
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		var e entry
		if err := json.Unmarshal(scanner.Bytes(), &e); err != nil {
			continue
		}
		if e.Skill == "" {
			continue
		}
		if !cutoff.IsZero() {
			t, err := time.Parse(time.RFC3339, e.TS)
			if err != nil {
				continue
			}
			if t.Before(cutoff) {
				continue
			}
		}
		entries = append(entries, e)
	}
	return entries
}

// countBySkill aggregates entries into a map of skill name to count.
func countBySkill(entries []entry) map[string]int {
	counts := make(map[string]int)
	for _, e := range entries {
		counts[e.Skill]++
	}
	return counts
}

// sortedCounts returns counts sorted descending by count.
func sortedCounts(counts map[string]int) []skillCount {
	result := make([]skillCount, 0, len(counts))
	for name, count := range counts {
		result = append(result, skillCount{Name: name, Count: count})
	}
	sort.Slice(result, func(i, j int) bool {
		if result[i].Count != result[j].Count {
			return result[i].Count > result[j].Count
		}
		return result[i].Name < result[j].Name
	})
	return result
}

// discoverSkills lists all installed skill directory names.
func discoverSkills(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var skills []string
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		name := e.Name()
		if strings.HasPrefix(name, "_") || strings.HasPrefix(name, ".") {
			continue
		}
		skills = append(skills, name)
	}
	sort.Strings(skills)
	return skills
}

// renderChart prints an ASCII bar chart of skill usage.
func renderChart(counts map[string]int, limit int, period string) {
	sorted := sortedCounts(counts)
	if limit > 0 && len(sorted) > limit {
		sorted = sorted[:limit]
	}

	// Find max count and max name length for alignment.
	maxCount := 0
	maxName := 0
	for _, sc := range sorted {
		if sc.Count > maxCount {
			maxCount = sc.Count
		}
		if len(sc.Name) > maxName {
			maxName = len(sc.Name)
		}
	}
	if maxName > 25 {
		maxName = 25
	}

	total := 0
	for _, c := range counts {
		total += c
	}

	barWidth := 40
	cyan := color.New(color.FgCyan)
	dim := color.New(color.Faint)

	fmt.Printf("\n")
	color.New(color.Bold).Printf("  Skill usage — past %s (%d invocations)\n\n", period, total)

	for _, sc := range sorted {
		name := sc.Name
		if len(name) > 25 {
			name = name[:22] + "..."
		}
		barLen := (sc.Count * barWidth) / maxCount
		if barLen == 0 && sc.Count > 0 {
			barLen = 1
		}
		bar := strings.Repeat("█", barLen)
		pct := float64(sc.Count) / float64(total) * 100

		fmt.Printf("  %-*s ", maxName, name)
		cyan.Printf("%-*s", barWidth, bar)
		dim.Printf(" %3d (%4.1f%%)\n", sc.Count, pct)
	}
	fmt.Printf("\n")
}

// suggestion holds the structured output for suggest --json mode.
type suggestion struct {
	TopSkills  []skillCount `json:"top_skills"`
	NeverUsed  []string     `json:"never_used"`
	RarelyUsed []skillCount `json:"rarely_used"`
}

// buildSuggestion creates a structured suggestion from usage data.
func buildSuggestion(counts map[string]int, allSkills []string) suggestion {
	sorted := sortedCounts(counts)

	top := sorted
	if len(top) > 5 {
		top = top[:5]
	}

	var neverUsed []string
	var rarelyUsed []skillCount
	for _, skill := range allSkills {
		c := counts[skill]
		if c == 0 {
			neverUsed = append(neverUsed, skill)
		} else if c <= 2 {
			rarelyUsed = append(rarelyUsed, skillCount{Name: skill, Count: c})
		}
	}

	return suggestion{
		TopSkills:  top,
		NeverUsed:  neverUsed,
		RarelyUsed: rarelyUsed,
	}
}

// suggestMode prints usage suggestions with colored output.
func suggestMode(counts map[string]int, allSkills []string, period string) {
	s := buildSuggestion(counts, allSkills)
	bold := color.New(color.Bold)
	green := color.New(color.FgGreen)
	yellow := color.New(color.FgYellow)
	red := color.New(color.FgRed)

	fmt.Printf("\n")
	bold.Printf("  Skill suggestions — past %s\n", period)

	// Top skills
	if len(s.TopSkills) > 0 {
		fmt.Printf("\n")
		green.Printf("  ★ Highest leverage\n")
		for _, sc := range s.TopSkills {
			fmt.Printf("    %-25s %d uses\n", sc.Name, sc.Count)
		}
	}

	// Never used
	if len(s.NeverUsed) > 0 {
		fmt.Printf("\n")
		red.Printf("  ✕ Never used (%d skills)\n", len(s.NeverUsed))
		for _, name := range s.NeverUsed {
			fmt.Printf("    %s\n", name)
		}
	}

	// Rarely used
	if len(s.RarelyUsed) > 0 {
		fmt.Printf("\n")
		yellow.Printf("  ~ Rarely used\n")
		for _, sc := range s.RarelyUsed {
			fmt.Printf("    %-25s %d uses\n", sc.Name, sc.Count)
		}
	}

	fmt.Printf("\n")
	if len(s.NeverUsed) > 0 {
		color.New(color.Faint).Printf("  Consider removing %d unused skills to reduce context overhead.\n\n", len(s.NeverUsed))
	}
}
