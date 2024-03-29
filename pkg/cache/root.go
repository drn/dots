// Package cache provides functionality to manage basic file-based caching
// located at ~/.dots/sys/cache
package cache

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"time"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
)

// Log - logs data from input cache key if less than specified TTL (in minutes)
// and exits with a successful status, otherwise returns
func Log(key string, ttl float64) {
	data := Read(key, ttl)
	if data != "" {
		log.Info(data)
		os.Exit(0)
	}
}

// Warm - returns true if the last write to the cache key less than the
// specified TTL(in minutes). False if the cache key doesn't exist or is older
// than the specified TTL
func Warm(key string, ttl float64) bool {
	cachePath := path.FromCache(key)
	info, err := os.Stat(cachePath)
	if err != nil {
		return false
	}
	age := time.Now().Sub(info.ModTime())
	return age.Minutes() <= ttl
}

// Touch - writes an empty string to the cache key
func Touch(key string) {
	Write(key, "")
}

// Read - returns data from input cache key if less than specified TTL (in
// minutes)
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
