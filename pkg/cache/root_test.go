package cache

import (
	"os"
	"testing"
	"time"

	"github.com/drn/dots/pkg/path"
)

// testKey generates a unique cache key for testing to avoid collisions
const testPrefix = "_test_cache_"

func cleanupKey(key string) {
	os.Remove(path.FromCache(key))
}

func TestWriteAndRead(t *testing.T) {
	key := testPrefix + "write-read"
	defer cleanupKey(key)

	Write(key, "hello world")
	data := Read(key, 60)
	if data != "hello world" {
		t.Errorf("expected 'hello world', got '%s'", data)
	}
}

func TestReadMissingKey(t *testing.T) {
	data := Read(testPrefix+"nonexistent", 60)
	if data != "" {
		t.Errorf("expected empty string for missing key, got '%s'", data)
	}
}

func TestReadExpiredTTL(t *testing.T) {
	key := testPrefix + "expired"
	defer cleanupKey(key)

	Write(key, "stale data")

	// Set the file modification time to 2 minutes ago
	cachePath := path.FromCache(key)
	past := time.Now().Add(-2 * time.Minute)
	os.Chtimes(cachePath, past, past)

	data := Read(key, 1) // 1 minute TTL
	if data != "" {
		t.Errorf("expected empty string for expired key, got '%s'", data)
	}
}

func TestWarm(t *testing.T) {
	key := testPrefix + "warm"
	defer cleanupKey(key)

	if Warm(testPrefix+"missing", 60) {
		t.Error("expected Warm to return false for missing key")
	}

	Write(key, "data")
	if !Warm(key, 60) {
		t.Error("expected Warm to return true for fresh key")
	}
}

func TestTouch(t *testing.T) {
	key := testPrefix + "touch"
	defer cleanupKey(key)

	Touch(key)
	data := Read(key, 60)
	if data != "" {
		t.Errorf("expected empty string from Touch, got '%s'", data)
	}

	// Verify the file exists
	if !Warm(key, 60) {
		t.Error("expected key to exist after Touch")
	}
}
