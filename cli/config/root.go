// Package config provides functionality to interact with and modify dots
// configuration stored as an INI file located at ~/.dots/sys/config
package config

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/go-ini/ini"
	"github.com/manifoldco/promptui"
)

// All - Returns a mapping of all the config stored in ~/.dots/sys/config
func All() map[string]map[string]string {
	var all = map[string]map[string]string{}
	for _, section := range config().Sections() {
		if len(section.Keys()) == 0 {
			continue
		}
		all[section.Name()] = section.KeysHash()
	}
	return all
}

// Fetch - Return a pointer to the config at the specified path. If the input
// is not set, run the optional onUnset input and prompt the user to specify
// the given config. If the secure parameter is true, mask the input data.
func Fetch(path string, onUnset *func(), secure bool) *string {
	section, key := parsePath(path)
	if section == nil || key == nil {
		log.Error("Invalid config.Fetch(%s)", path)
		return nil
	}

	value := Read(path)
	if value == "" {
		if onUnset != nil {
			(*onUnset)()
		}
		value = ask(*section, *key, secure)
		if value == "" {
			return nil
		}
		Write(path, value)
	}

	return &value
}

// Read - Return the config at the specified path.
func Read(path string) string {
	section, key := parsePath(path)
	if section == nil || key == nil {
		return ""
	}
	return config().Section(*section).Key(*key).String()
}

// Write - Write the value to the specified config path.
func Write(path string, value string) bool {
	section, key := parsePath(path)
	if section == nil || key == nil {
		return false
	}
	config := config()
	config.Section(*section).Key(*key).SetValue(value)
	save(config)
	return true
}

// Delete - Delete the config at the spcified config path.
func Delete(path string) {
	section, key := parsePath(path)
	if section == nil {
		return
	}
	config := config()
	if key == nil {
		config.DeleteSection(*section)
	} else {
		config.Section(*section).DeleteKey(*key)
	}
	save(config)
}

// ask - Prompts user for input for the given config section and key.
func ask(section string, key string, secure bool) string {
	label := fmt.Sprintf("%s %s?", strings.ToUpper(section[:1])+section[1:], key)

	var mask rune
	if secure {
		mask = '*'
	}

	prompt := promptui.Prompt{
		Label:    label,
		Validate: validateInput,
		Mask:     mask,
	}

	value, err := prompt.Run()
	if err != nil {
		return ""
	}
	return value
}

func validateInput(input string) error {
	if strings.TrimSpace(input) == "" {
		return errors.New("must not be blank")
	}
	return nil
}

func parsePath(key string) (*string, *string) {
	parts := strings.Split(key, ".")
	switch len(parts) {
	case 0:
		return nil, nil
	case 1:
		return &parts[0], nil
	}
	return &parts[0], &parts[1]
}

func save(config *ini.File) {
	os.Mkdir(path.FromHome(".dots/sys"), os.ModePerm)
	config.SaveTo(configPath())
}

func config() *ini.File {
	cfg, err := ini.Load(configPath())
	if err != nil {
		cfg = ini.Empty()
	}
	return cfg
}

func configPath() string {
	return path.FromHome(".dots/sys/config")
}
