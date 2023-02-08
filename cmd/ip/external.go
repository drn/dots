package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/drn/dots/pkg/cache"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

var services = []string{
	fmt.Sprintf("ipinfo.io/ip?token=%s", os.Getenv("IPINFO_API_KEY")),
	"ipv4.icanhazip.com",
	"wtfismyip.com/text",
	"ipecho.net/plain",
	"ifconfig.me",
	"ifconfig.co",
	"l2.io/ip",
}

func external(useCache bool) {
	if useCache {
		cache.Log("ip-external", 5)
	}
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
		cache.Write("ip-external", ip)
		os.Exit(0)
	}
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
