package install

import (
	"os"

	"github.com/drn/dots/cli/is"
	"github.com/drn/dots/pkg/log"
)

// Osx - Sets OSX configuration
func (i Install) Osx() {
	log.Action("Installing OSX config")

	if !is.Osx() {
		log.Error("Cannot install OSX configuration on a non-darwin machine")
		os.Exit(0)
	}

	log.Info("Configuring system key press speeds")
	// disable key hold popup menu
	exec("defaults write -g ApplePressAndHoldEnabled -bool false")
	// set key repeat rates
	exec("defaults write -g InitialKeyRepeat -int 15")
	exec("defaults write -g KeyRepeat -int 3")

	log.Info("Disabling natural scrolling")
	exec(
		"defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false",
	)

	log.Info("Enabling Finder status bar")
	exec("defaults write com.apple.finder ShowStatusBar -bool true")

	log.Info("Setting hidden dock applications as translucent")
	exec("defaults write com.apple.dock showhidden -bool true")

	log.Info("Setting Notification Center banner display time")
	exec("defaults write com.apple.notificationcenterui bannerTime 2.5")

	log.Info("Disabling autocorrect")
	exec(
		"defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false",
	)

	log.Info("Disable natural scroll")
	exec(
		"defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false",
	)

	log.Info("Disable screenshot previews")
	exec(
		"defaults write com.apple.screencapture show-thumbnail -bool false",
	)

	log.Info("Disable iTunes auto-start when devices are plugged in")
	exec(
		"defaults write com.apple.iTunesHelper ignore-devices 1",
	)

	log.Info("Display all file extensions in Finder")
	exec(
		"defaults write NSGlobalDomain AppleShowAllExtensions -bool true",
	)

	log.Info("Set screenshot directory to ~/Downloads")
	exec(
		"defaults write com.apple.screencapture location ~/Downloads",
	)

	log.Info("Ensuring changes take effect immediately")
	exec("killall Dock")
	exec("killall Finder")
	exec("killall SystemUIServer")
}
