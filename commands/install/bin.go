package install

// Bin - Symlinks ~/bin directory
func Bin() {
  link("lib/bin", "bin")
}
