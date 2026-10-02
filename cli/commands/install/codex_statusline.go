package install

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

var codexStatusLineItems = []string{
	"model-with-reasoning",
	"context-remaining",
	"five-hour-limit",
	"weekly-limit",
}

func registerCodexStatusLine() {
	configPath := codexConfigPath()
	data, err := os.ReadFile(configPath)
	if err != nil && !os.IsNotExist(err) {
		log.Warning("Failed to read Codex config: %s", err.Error())
		return
	}

	updated, changed, err := ensureCodexStatusLine(string(data))
	if err != nil {
		log.Warning("Failed to update Codex status line: %s", err.Error())
		return
	}
	if !changed {
		return
	}

	mode := os.FileMode(0600)
	if info, statErr := os.Stat(configPath); statErr == nil {
		mode = info.Mode().Perm()
	}
	if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
		log.Warning("Failed to create Codex config directory: %s", err.Error())
		return
	}
	if err := writeFileAtomic(configPath, []byte(updated), mode); err != nil {
		log.Warning("Failed to write Codex config: %s", err.Error())
		return
	}
	log.Success("Registered Codex status line (model, context, and limits)")
}

func codexConfigPath() string {
	codexHome := os.Getenv("CODEX_HOME")
	if codexHome == "" {
		codexHome = path.FromHome(".codex")
	}
	return filepath.Join(codexHome, "config.toml")
}

func ensureCodexStatusLine(config string) (string, bool, error) {
	location := findCodexStatusLine(config)
	if location.targetStart >= 0 {
		return updateCodexStatusLine(config, location.targetStart)
	}

	var missing []string
	appendMissingStatusLineItems(&missing)
	value := "status_line = " + formatTomlStringArray(missing) + "\n"
	if location.tuiStart >= 0 {
		return config[:location.tuiEnd] + value + config[location.tuiEnd:], true, nil
	}

	// Put a dotted key before any table so it remains in the root TOML scope.
	if location.firstTable < 0 {
		if config != "" && !strings.HasSuffix(config, "\n") {
			config += "\n"
		}
		return config + "[tui]\n" + value, true, nil
	}
	return config[:location.firstTable] + "tui.status_line = " + formatTomlStringArray(missing) + "\n\n" + config[location.firstTable:], true, nil
}

type codexStatusLineLocation struct {
	tuiStart    int
	tuiEnd      int
	targetStart int
	firstTable  int
}

func findCodexStatusLine(config string) codexStatusLineLocation {
	lines := strings.SplitAfter(config, "\n")
	section := ""
	location := codexStatusLineLocation{tuiStart: -1, tuiEnd: -1, targetStart: -1, firstTable: -1}
	offset := 0
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "[") && strings.HasSuffix(trimmed, "]") {
			if location.firstTable < 0 {
				location.firstTable = offset
			}
			section = strings.TrimSpace(trimmed[1 : len(trimmed)-1])
			if section == "tui" {
				location.tuiStart = offset
				location.tuiEnd = offset + len(line)
			}
		} else if section == "tui" && location.tuiStart >= 0 {
			location.tuiEnd = offset + len(line)
		}

		key, value, hasValue := strings.Cut(strings.SplitN(trimmed, "#", 2)[0], "=")
		if hasValue && (section == "tui" && strings.TrimSpace(key) == "status_line" || section == "" && strings.TrimSpace(key) == "tui.status_line") {
			location.targetStart = offset + strings.Index(line, value)
		}
		offset += len(line)
	}
	return location
}

func updateCodexStatusLine(config string, start int) (string, bool, error) {
	for start < len(config) && isSpace(config[start]) {
		start++
	}
	if start >= len(config) || config[start] != '[' {
		return config, false, fmt.Errorf("tui.status_line must be an array of strings")
	}
	end, err := tomlArrayEnd(config, start, len(config))
	if err != nil {
		return config, false, err
	}
	items, err := parseTomlStringArray(config[start:end])
	if err != nil {
		return config, false, err
	}
	if !appendMissingStatusLineItems(&items) {
		return config, false, nil
	}
	return config[:start] + formatTomlStringArray(items) + config[end:], true, nil
}

func appendMissingStatusLineItems(items *[]string) bool {
	changed := false
	for _, wanted := range codexStatusLineItems {
		found := false
		for _, item := range *items {
			if item == wanted {
				found = true
				break
			}
		}
		if !found {
			*items = append(*items, wanted)
			changed = true
		}
	}
	return changed
}

func formatTomlStringArray(items []string) string {
	quoted := make([]string, 0, len(items))
	for _, item := range items {
		quoted = append(quoted, strconv.Quote(item))
	}
	return "[" + strings.Join(quoted, ", ") + "]"
}

func parseTomlStringArray(value string) ([]string, error) {
	if len(value) < 2 || value[0] != '[' || value[len(value)-1] != ']' {
		return nil, fmt.Errorf("tui.status_line must be an array of strings")
	}
	body := value[1 : len(value)-1]
	var items []string
	for i := 0; i < len(body); {
		i = skipTomlArrayTrivia(body, i)
		if i == len(body) {
			break
		}
		item, next, err := parseTomlString(body, i)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
		i = next
	}
	return items, nil
}

func skipTomlArrayTrivia(body string, i int) int {
	for i < len(body) {
		if isSpace(body[i]) || body[i] == ',' {
			i++
			continue
		}
		if body[i] == '#' {
			for i < len(body) && body[i] != '\n' {
				i++
			}
			continue
		}
		break
	}
	return i
}

func parseTomlString(body string, start int) (string, int, error) {
	quote := body[start]
	if quote != '"' && quote != '\'' {
		return "", start, fmt.Errorf("tui.status_line contains a non-string value")
	}
	end := start + 1
	for end < len(body) {
		if quote == '"' && body[end] == '\\' {
			end += 2
			continue
		}
		if body[end] == quote {
			end++
			break
		}
		end++
	}
	if end > len(body) || body[end-1] != quote {
		return "", start, fmt.Errorf("unterminated string in tui.status_line")
	}
	raw := body[start:end]
	if quote == '\'' {
		return raw[1 : len(raw)-1], end, nil
	}
	item, err := strconv.Unquote(raw)
	if err != nil {
		return "", start, fmt.Errorf("invalid string in tui.status_line: %w", err)
	}
	return item, end, nil
}

func tomlArrayEnd(config string, start, limit int) (int, error) {
	state := tomlArrayScanState{}
	for i := start + 1; i < limit; i++ {
		if state.consume(config[i]) {
			return i + 1, nil
		}
	}
	return 0, fmt.Errorf("unterminated tui.status_line array")
}

type tomlArrayScanState struct {
	quote   byte
	escaped bool
	comment bool
}

func (state *tomlArrayScanState) consume(char byte) bool {
	if state.comment {
		state.comment = char != '\n'
		return false
	}
	if state.quote != 0 {
		if state.quote == '"' && state.escaped {
			state.escaped = false
		} else if state.quote == '"' && char == '\\' {
			state.escaped = true
		} else if char == state.quote {
			state.quote = 0
		}
		return false
	}
	if char == '#' {
		state.comment = true
	} else if char == '"' || char == '\'' {
		state.quote = char
	}
	return char == ']'
}

func isSpace(value byte) bool {
	return value == ' ' || value == '\t' || value == '\r' || value == '\n'
}
