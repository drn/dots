package install

import (
	"os"
	"reflect"
	"strings"

	"github.com/drn/dots/pkg/run"
)

// Install - Struct containing all install commands
type Install struct{}

// Call - Call install command by name
func Call(command string) {
	var i Install
	command = strings.Title(command)
	reflect.ValueOf(&i).MethodByName(command).Call([]reflect.Value{})
}

// Verbosely runs a command and fails if the command fails
func exec(command string, args ...interface{}) {
	if !run.Verbose(command, args...) {
		os.Exit(1)
	}
}
