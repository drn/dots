package spinner

import (
	"fmt"
	"time"
)

// Spin - Runs a spinner based on the input set of runes
func Spin(chars []rune) {
	i := 0
	length := len(chars)
	for {
		char := chars[i]
		fmt.Printf("\r%s", string(char))
		time.Sleep(time.Second / 4)
		i++
		if i == length {
			i = 0
		}
	}
}
