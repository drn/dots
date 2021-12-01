package install

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"github.com/drn/dots/cli/is"
	"github.com/drn/dots/cli/link"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
	"github.com/drn/dots/cli/run"
)

// Vim - Installs vim configuration
func (i Install) Vim() {
	log.Action("Installing vim config")
	vimLinkConfig()
	vimLinkNeovim()
	vimUpdatePlug()
	vimUpdatePlugins()
}

func vimLinkConfig() {
	log.Info("Ensuring all vim configuration is linked:")
	os.Mkdir(path.FromHome(".vim"), os.ModePerm)
	files, _ := ioutil.ReadDir(path.FromDots("vim"))
	for _, file := range files {
		link.Soft(
			path.FromDots("vim/%s", file.Name()),
			path.FromHome(".vim/%s", file.Name()),
		)
	}
}

func vimLinkNeovim() {
	os.Mkdir(path.FromHome(".config"), os.ModePerm)
	link.Soft(
		path.FromHome(".vim"),
		path.FromHome(".config/nvim"),
	)
	link.Soft(path.FromHome(".vim"), path.FromHome(".nvim"))
	link.Soft(path.FromHome(".vimrc"), path.FromHome(".nvimrc"))
	link.Soft(path.FromHome(".vimrc"), path.FromHome(".config/nvim/init.vim"))
}

func vimUpdatePlug() {
	plugPath := path.FromHome(".vim/autoload/plug.vim")
	if !is.File(plugPath) {
		url := "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
		exec(
			"curl -fLo %s --create-dirs %s",
			plugPath,
			url,
		)
	}
}

func vimUpdatePlugins() {
	log.Info("Updating vim plugins:")
	tempPath := "/tmp/vim-update-result"
	os.Remove(tempPath)
	run.Silent(
		"nvim -c \"%s\"",
		strings.Join(
			[]string{
				"PlugUpgrade",
				"PlugUpdate",
				"set modifiable",
				"4d", "2d", "2d", "1d",
				"execute line('$')",
				"put=''", "pu",
				fmt.Sprintf("w %s", tempPath),
				"q", "q", "q", "q",
			},
			"|",
		),
	)
	bytes, err := ioutil.ReadFile(tempPath)
	if err == nil {
		fmt.Println(string(bytes))
	}
}
