package install

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"

	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/drn/dots/pkg/run"
)

const (
	piDefaultProvider = "ollama"
	piDefaultModel    = "qwen3:32b"
)

// Pi - Installs pi.dev coding agent and configuration
//
// Only models.json is tracked. auth.json (provider API keys) and sessions/
// (per-session state) stay local and out of git.
func Pi() {
	log.Action("Install pi.dev")

	installPi()

	// Always reconcile the config symlink, even if the binary is already
	// installed — re-running `dots install pi` should restore the link if
	// it was removed or replaced.
	agentDir := path.FromHome(".pi/agent")
	if err := os.MkdirAll(agentDir, 0755); err != nil {
		log.Error("Failed to create %s: %s", agentDir, err.Error())
		return
	}

	link.Soft(
		path.FromDots("pi/agent/models.json"),
		path.FromHome(".pi/agent/models.json"),
	)

	if err := seedPiSettings(path.FromHome(".pi/agent/settings.json")); err != nil {
		log.Warning("Failed to seed pi.dev settings: %s", err.Error())
	}
}

func installPi() {
	if err := run.Silent("which pi"); err == nil {
		log.Info("pi.dev already installed")
		return
	}
	exec("curl -fsSL https://pi.dev/install.sh | sh")
}

// seedPiSettings ensures defaultProvider and defaultModel are set in pi.dev's
// settings.json, merging into any existing content (e.g. lastChangelogVersion
// written by pi.dev itself). Idempotent — a no-op when both fields already
// match the seeded values. Writes atomically via tempfile + rename so a
// concurrent pi.dev save can't observe a half-written file.
func seedPiSettings(settingsPath string) error {
	fileMode := os.FileMode(0600)
	settings := map[string]any{}

	data, err := os.ReadFile(settingsPath)
	if err == nil {
		if info, statErr := os.Stat(settingsPath); statErr == nil {
			fileMode = info.Mode().Perm()
		}
		if len(data) > 0 {
			if err := json.Unmarshal(data, &settings); err != nil {
				return err
			}
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return err
	}

	// Idempotency check assumes both fields are strings when present, which is
	// the schema pi.dev uses. A non-string value falls through and gets
	// overwritten — desirable for a malformed schema.
	if settings["defaultProvider"] == piDefaultProvider && settings["defaultModel"] == piDefaultModel {
		return nil
	}
	settings["defaultProvider"] = piDefaultProvider
	settings["defaultModel"] = piDefaultModel

	out, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return err
	}
	return writeFileAtomic(settingsPath, append(out, '\n'), fileMode)
}

// writeFileAtomic writes data to path via a sibling tempfile + rename so a
// concurrent reader never observes a partial file.
func writeFileAtomic(path string, data []byte, mode os.FileMode) error {
	tmp, err := os.CreateTemp(filepath.Dir(path), ".tmp-*")
	if err != nil {
		return err
	}
	tmpPath := tmp.Name()
	defer os.Remove(tmpPath)

	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Chmod(mode); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmpPath, path)
}
