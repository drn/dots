package main

import (
	"io/ioutil"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
	"github.com/drn/dots/cli/run"
)

var services = []string{
	"ipv4.icanhazip.com",
	"wtfismyip.com/text",
	"ipecho.net/plain",
	"ipinfo.io/ip",
	"ifconfig.me",
	"ifconfig.co",
	"l2.io/ip",
}

func main() {
	checkCache()
	check(google())
	check(opendns())
	for _, service := range services {
		check(curl(service))
	}
	os.Exit(1)
}

func check(ip string) {
	if isValid(ip) {
		log.Info(ip)
		cache(ip)
		os.Exit(0)
	}
}

// Read IP from ~/.ip cache if less than 5min TTL
func checkCache() {
	info, err := os.Stat(cachePath())
	if err != nil {
		return
	}
	age := time.Now().Sub(info.ModTime())
	if age.Minutes() > 5 {
		return
	}
	data, _ := ioutil.ReadFile(cachePath())
	log.Info(string(data))
	os.Exit(0)
}

func cache(ip string) {
	file, _ := os.Create(cachePath())
	file.WriteString(ip)
	file.Close()
}

func cachePath() string {
	return path.FromHome(".ip")
}

func google() string {
	return capture("dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com")
}

func opendns() string {
	return capture("dig +short myip.opendns.com @resolver1.opendns.com")
}

func curl(endpoint string) string {
	return capture("curl -s4 \"%s\"", endpoint)
}

func capture(command string, args ...interface{}) string {
	data := run.Capture(command+" 2>/dev/null", args...)
	return strings.Trim(data, "\"")
}

func isValid(data string) bool {
	result, _ := regexp.MatchString("^\\d+.\\d+.\\d+.\\d+$", data)
	return result
}
