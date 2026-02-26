package install

import (
	"testing"
)

func TestCall_UnknownCommand(_ *testing.T) {
	// Should be a no-op, not panic
	Call("definitely-not-a-command")
}

func TestCall_EmptyCommand(_ *testing.T) {
	// Should be a no-op, not panic
	Call("")
}
