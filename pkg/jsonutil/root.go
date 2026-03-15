// Package jsonutil provides shared JSON output helpers
package jsonutil

import (
	"encoding/json"
	"os"
)

// Print writes v as indented JSON to stdout.
func Print(v interface{}) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	enc.Encode(v)
}
