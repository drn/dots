package install

import (
  "os"
  "runtime"
  "github.com/drn/dots/log"
  "github.com/drn/dots/util"
)

// Osx - Sets OSX configuration
func Osx() {
  log.Action("Installing OSX config")

  if !isOsx() {
    log.Error("Cannot install OSX configuration on a non-darwin machine")
    os.Exit(0)
  }

  log.Info("Configuring system key press speeds")
  // disable key hold popup menu
  util.Run("defaults write -g ApplePressAndHoldEnabled -bool false")
  // set key repeat rates
  util.Run("defaults write -g InitialKeyRepeat -int 12")
  util.Run("defaults write -g KeyRepeat -int 3")

  log.Info("Disabling natural scrolling")
  util.Run(
    "defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false",
  )

  log.Info("Enabling Finder status bar")
  util.Run("defaults write com.apple.finder ShowStatusBar -bool true")

  log.Info("Setting hidden dock applications as translucent")
  util.Run("defaults write com.apple.dock showhidden -bool true")

  log.Info("Setting Notification Center banner display time")
  util.Run("defaults write com.apple.notificationcenterui bannerTime 2.5")

  log.Info("Disabling autocorrect")
  util.Run("defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false")

  log.Info("Disable natural scroll")
  util.Run(
    "defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false",
  )

  log.Info("Ensuring changes take effect immediately")
  util.Run("killall Dock")
  util.Run("killall Finder")
  util.Run("killall SystemUIServer")
}

func isOsx() bool {
  return runtime.GOOS == "darwin"
}
