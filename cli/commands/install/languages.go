package install

import (
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
	"github.com/drn/dots/cli/run"
)

// versions - installed language versions
var versions = map[string]string{
	"ruby":      "2.5.1",
	"python2":   "2.7.18",
	"python3":   "3.9.1",
	"terraform": "1.0.11",
	"nodejs":    "17.2.0",
}

// Languages - Installs asdf & languages
func (i Install) Languages() {
	log.Action("Installing asdf")
	log.Info("Ensuring asdf is installed")
	exec("brew install asdf")
	ruby()
	python()
	terraform()
	nodejs()
}

func ruby() {
	asdfPlugin("ruby", "asdf-vm/asdf-ruby")
	asdfVersion("ruby", versions["ruby"])
	exec("gem install neovim")
}

func python() {
	asdfPlugin("python", "danhper/asdf-python")

	asdfVersion("python", versions["python2"])
	log.Info("Installing python2 neovim dependencies")
	exec("pip install --upgrade pip pynvim wakatime")

	asdfVersion("python", versions["python3"])
	log.Info("Installing python3 neovim dependencies")
	exec("pip install --upgrade pip pynvim flake8 wakatime")
	log.Info("Linking flake8 linter")
	exec("asdf reshim python")
	link.Soft(run.Capture("asdf which flake8"), path.FromHome("bin/flake8"))
}

func terraform() {
	asdfPlugin("terraform", "asdf-community/asdf-hashicorp")
	asdfVersion("terraform", versions["terraform"])
}

func nodejs() {
	asdfPlugin("nodejs", "asdf-vm/asdf-nodejs")
	asdfVersion("nodejs", versions["nodejs"])
}

func asdfVersion(language string, version string) {
	log.Info("Installing %s %s", language, version)
	exec("asdf install %s %s", language, version)
	exec("asdf global %s %s", language, version)
}

func asdfPlugin(language string, path string) {
	log.Info("Configure %s asdf plugin", language)
	exec("asdf plugin add %s https://github.com/%s || true", language, path)
}
