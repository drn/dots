package cache

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"time"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Log - logs data from input cache key if less than specified TTL and exits
// with a successful status, otherwise returns
func Log(key string, ttl float64) {
	data := Read(key, 5)
	if data != "" {
		log.Info(data)
		os.Exit(0)
	}
}

// Read - returns data from input cache key if less than specified TTL
func Read(key string, ttl float64) string {
	cachePath := path.FromCache(key)
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

// Write - stores input string at specified cache key
func Write(key string, data string) {
	cachePath := path.FromCache(key)
	// create directory hierarchy if it doesn't exist
	os.MkdirAll(filepath.Dir(cachePath), os.ModePerm)
	file, _ := os.Create(cachePath)
	file.WriteString(data)
	file.Close()
}
