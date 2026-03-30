// Package path returns path-related helper functions
package path //revive:disable-line:var-naming

import (
	"fmt"
	"os"
	"os/user"
	"strings"
	"sync"
)

// Pretty - Pretty prints the input path
func Pretty(path string) string {
	path = strings.Replace(path, Dots(), "$DOTS", 1)
	path = strings.Replace(path, Home(), "~", 1)
	return path
}

// Dots - Returns $DOTS path
func Dots() string {
	path := os.Getenv("DOTS")
	if path == "" {
		path = fmt.Sprintf("%s/.dots", Home())
	}
	return path
}

// FromDots - Returns path relative to $DOTS
func FromDots(path string, args ...interface{}) string {
	return fmt.Sprintf("%s/%s", Dots(), fmt.Sprintf(path, args...))
}

// homeOverride allows tests to redirect Home() to a temp directory.
// Not intended for production use — call only from test code.
var (
	homeOverride string
	homeMu       sync.RWMutex
)

// SetHome overrides the home directory for testing. Pass "" to clear.
// This is not goroutine-safe with concurrent callers in production;
// use only from test setup/teardown via t.Cleanup.
func SetHome(dir string) {
	homeMu.Lock()
	homeOverride = dir
	homeMu.Unlock()
}

// Home - Returns $HOME path
func Home() string {
	homeMu.RLock()
	override := homeOverride
	homeMu.RUnlock()
	if override != "" {
		return override
	}
	u, err := user.Current()
	if err != nil {
		if home := os.Getenv("HOME"); home != "" {
			return home
		}
		panic(fmt.Sprintf("failed to determine home directory: %s", err.Error()))
	}
	return u.HomeDir
}

// FromHome - Returns path relative to $HOME
func FromHome(path string, args ...interface{}) string {
	return fmt.Sprintf("%s/%s", Home(), fmt.Sprintf(path, args...))
}

// Cache - Returns $HOME/.dots/cache path
func Cache() string {
	return fmt.Sprintf("%s/.dots/sys/cache", Home())
}

// FromCache - Returns path to cache
func FromCache(path string, args ...interface{}) string {
	return fmt.Sprintf("%s/%s", Cache(), fmt.Sprintf(path, args...))
}
