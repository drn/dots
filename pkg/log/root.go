// Package log provides various colorized logging functions
package log //revive:disable-line:var-naming

import (
	"fmt"

	"github.com/drn/dots/pkg/path"
	"github.com/fatih/color"
)

// Level controls which log messages are emitted.
type Level int

const (
	// LevelQuiet emits only warnings and errors.
	LevelQuiet Level = iota
	// LevelNormal emits informational output and above (the default).
	LevelNormal
	// LevelVerbose emits everything, including debug detail.
	LevelVerbose
)

var currentLevel = LevelNormal

// SetLevel sets the active log level.
func SetLevel(level Level) {
	currentLevel = level
}

// GetLevel returns the active log level.
func GetLevel() Level {
	return currentLevel
}

// Action - Logs command in appropriate color
func Action(output string, args ...interface{}) {
	if currentLevel < LevelNormal {
		return
	}
	color.Magenta(output, args...)
}

// Info - Logs info in appropriate color
func Info(output string, args ...interface{}) {
	if currentLevel < LevelNormal {
		return
	}
	color.Blue(output, args...)
}

// Success - Logs success in appropriate color
func Success(output string, args ...interface{}) {
	if currentLevel < LevelNormal {
		return
	}
	color.Green(output, args...)
}

// Error - Logs error in appropriate color. Always emitted.
func Error(output string, args ...interface{}) {
	color.Red(output, args...)
}

// Warning - Logs warning in appropriate color. Always emitted.
func Warning(output string, args ...interface{}) {
	color.Yellow(output, args...)
}

// Debug - Logs debug detail in appropriate color. Emitted only at verbose level.
func Debug(output string, args ...interface{}) {
	if currentLevel < LevelVerbose {
		return
	}
	color.Cyan(output, args...)
}

// Command - Logs command in appropriate color
func Command(output string, args ...interface{}) {
	if currentLevel < LevelNormal {
		return
	}
	output = path.Pretty(fmt.Sprintf(output, args...))
	color.White("%s %s", color.BlueString("\u276F"), output)
}

// Raw - Logs command in appropriate color
func Raw(output string) {
	if currentLevel < LevelNormal {
		return
	}
	color.White("%s %s", color.BlueString("\u276F"), output)
}
