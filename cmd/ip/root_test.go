package main

import "testing"

func TestIsValid(t *testing.T) {
	valid := []string{
		"192.168.1.1",
		"10.0.0.1",
		"255.255.255.255",
		"0.0.0.0",
	}
	for _, ip := range valid {
		if !isValid(ip) {
			t.Errorf("isValid(%q) = false, want true", ip)
		}
	}

	invalid := []string{
		"",
		"192.168.1",
		"192.168.1.1.1",
		"192.168.1X1",
		"abc.def.ghi.jkl",
		"192.168.1.1\n",
		" 192.168.1.1",
		"192.168.1.1 ",
	}
	for _, ip := range invalid {
		if isValid(ip) {
			t.Errorf("isValid(%q) = true, want false", ip)
		}
	}
}
