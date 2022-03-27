package cache

import (
	"io/ioutil"
	"os"
	"time"

	"github.com/drn/dots/pkg/log"
)

// Log - logs data from input cache file if less than specified TTL and exits
// with a successful status, otherwise returns
func Log(cachePath string, ttl float64) {
	data := Read(cachePath, 5)
	if data != "" {
		log.Info(data)
		os.Exit(0)
	}
}

// Read - returns data from input cache file if less than specified TTL
func Read(cachePath string, ttl float64) string {
	info, err := os.Stat(cachePath)
	if err != nil {
		return ""
	}
	age := time.Now().Sub(info.ModTime())
	if age.Minutes() > ttl {
		return ""
	}
	data, _ := ioutil.ReadFile(cachePath)
	return string(data)
}

// Write - stores input string at specified cache path
func Write(cachePath string, data string) {
	file, _ := os.Create(cachePath)
	file.WriteString(data)
	file.Close()
}
