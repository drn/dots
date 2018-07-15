package log

import (
  "github.com/fatih/color"
)

// Action - Logs command in appropriate color
func Action(output string, args ...interface{}) {
  color.Magenta(output, args...)
}

// Info - Logs info in appropriate color
func Info(output string, args ...interface{}) {
  color.Blue(output, args...)
}

// Error - Logs error in appropriate color
func Error(output string, args ...interface{}) {
  color.Red(output, args...)
}
