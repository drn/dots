package install

import (
  "strings"
  "reflect"
)

// Install - Struct containing all install commands
type Install struct {}

// Call - Call install command by name
func Call(command string) {
  var i Install
  command = strings.Title(command)
  reflect.ValueOf(&i).MethodByName(command).Call([]reflect.Value{})
}
