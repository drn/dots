package install

// All - Runs all install scripts
func (i Install) All() {
  i.Home()
  i.Zsh()
  i.Homebrew()
  i.Bin()
  i.Git()
  i.Vim()
  i.Fonts()
  i.Npm()
  i.Osx()
  i.Hammerspoon()
}
