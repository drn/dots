package main

import (
	"io/ioutil"
	"os"
	"time"

	"github.com/drn/dots/pkg/log"
)

// Read IP from input cache file if less than 5min TTL
func checkCache(cachePath string) {
	info, err := os.Stat(cachePath)
	if err != nil {
		return
	}
	age := time.Now().Sub(info.ModTime())
	if age.Minutes() > 5 {
		return
	}
	data, _ := ioutil.ReadFile(cachePath)
	log.Info(string(data))
	os.Exit(0)
}

func cache(cachePath string, ip string) {
	file, _ := os.Create(cachePath)
	file.WriteString(ip)
	file.Close()
}
