package path

import (
	"fmt"
	"os"
	"os/user"
	"strings"
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

// Home - Returns $HOME path
func Home() string {
	user, _ := user.Current()
	return user.HomeDir
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
