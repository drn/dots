// Package cache provides functionality to manage basic file-based caching
// located at ~/.dots/sys/cache
package cache

import (
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
	age := time.Since(info.ModTime())
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
	age := time.Since(info.ModTime())
	if age.Minutes() > ttl {
		return ""
	}
	data, err := os.ReadFile(cachePath)
	if err != nil {
		log.Warning("Failed to read cache file %s: %s", cachePath, err.Error())
		return ""
	}
	return string(data)
}

// Write - stores input string at specified cache key atomically
func Write(key string, data string) {
	cachePath := path.FromCache(key)
	dir := filepath.Dir(cachePath)
	// create directory hierarchy if it doesn't exist
	if err := os.MkdirAll(dir, os.ModePerm); err != nil {
		log.Warning("Failed to create cache directory: %s", err.Error())
		return
	}
	// write to temp file then rename for atomicity
	tmp, err := os.CreateTemp(dir, ".cache-*")
	if err != nil {
		log.Warning("Failed to create temp cache file: %s", err.Error())
		return
	}
	tmpPath := tmp.Name()
	if _, err := tmp.WriteString(data); err != nil {
		tmp.Close()
		os.Remove(tmpPath)
		log.Warning("Failed to write cache data: %s", err.Error())
		return
	}
	tmp.Close()
	if err := os.Rename(tmpPath, cachePath); err != nil {
		os.Remove(tmpPath)
		log.Warning("Failed to rename cache file: %s", err.Error())
	}
}
