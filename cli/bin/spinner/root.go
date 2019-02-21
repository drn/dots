package main

import (
	"fmt"
	"time"
)

func main() {
	steps := []rune{
		'⠷',
		'⠯',
		'⠟',
		'⠻',
		'⠽',
		'⠾',
	}
	fmt.Print("⠿")

	i := 0
	length := len(steps)
	for {
		step := steps[i]
		fmt.Printf("\r%s", string(step))
		time.Sleep(time.Second / 8)
		i++
		if i == length {
			i = 0
		}
	}
}
