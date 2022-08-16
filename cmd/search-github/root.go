// Usage: search-github [github-org] [search-term]
// Opens browser to code search view for the input github org and search term.
package main

import (
	"os"
	"strings"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
)

func main() {
	if len(os.Args) < 3 {
		log.Error("Usage: search-github [github-org] [search-term]")
		os.Exit(1)
	}
	org := os.Args[1]
	searchTerm := strings.Join(os.Args[2:len(os.Args)], " ")

	run.Silent(
		"open 'https://github.com/search?type=code&q=org:%s %s'",
		org,
		searchTerm,
	)
}
