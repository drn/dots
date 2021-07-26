package install

import (
	"os"

	"github.com/drn/dots/cli/is"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/run"
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
	run.Verbose("defaults write -g ApplePressAndHoldEnabled -bool false")
	// set key repeat rates
	run.Verbose("defaults write -g InitialKeyRepeat -int 12")
	run.Verbose("defaults write -g KeyRepeat -int 3")

	log.Info("Disabling natural scrolling")
	run.Verbose(
		"defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false",
	)

	log.Info("Enabling Finder status bar")
	run.Verbose("defaults write com.apple.finder ShowStatusBar -bool true")

	log.Info("Setting hidden dock applications as translucent")
	run.Verbose("defaults write com.apple.dock showhidden -bool true")

	log.Info("Setting Notification Center banner display time")
	run.Verbose("defaults write com.apple.notificationcenterui bannerTime 2.5")

	log.Info("Disabling autocorrect")
	run.Verbose(
		"defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false",
	)

	log.Info("Disable natural scroll")
	run.Verbose(
		"defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false",
	)

	log.Info("Disable screenshot previews")
	run.Verbose(
		"defaults write com.apple.screencapture show-thumbnail -bool false",
	)

	log.Info("Disable iTunes auto-start when devices are plugged in")
	run.Verbose(
		"defaults write com.apple.iTunesHelper ignore-devices 1",
	)

	log.Info("Display all file extensions in Finder")
	run.Verbose(
		"defaults write NSGlobalDomain AppleShowAllExtensions -bool true",
	)

	log.Info("Ensuring changes take effect immediately")
	run.Verbose("killall Dock")
	run.Verbose("killall Finder")
	run.Verbose("killall SystemUIServer")
}
