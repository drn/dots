if [[ $OSTYPE != darwin* ]]; then
  echo 'Skipping OSX-specific installation'
  exit 0
fi

echo "Ensuring no sleepimage files are generated"
# set hibernate mode to desktop
sudo pmset -a hibernatemode 0
# remove sleepimage
sudo rm -f /private/var/vm/sleepimage
# create immutable placeholder sleepimage
sudo touch /private/var/vm/sleepimage
sudo chflags uchg /private/var/vm/sleepimage

echo "Disabling OS X programs"
# disable os x dashboard
defaults write com.apple.dashboard mcx-disabled -boolean YES
killall Dock

echo "Configuring system key press speeds"
# disable key hold popup menu
defaults write -g ApplePressAndHoldEnabled -bool false
# set key repeat rates
defaults write -g InitialKeyRepeat -int 12
defaults write -g KeyRepeat -int 3

echo "Disabling natural scrolling"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

echo "Enabling Finder status bar"
defaults write com.apple.finder ShowStatusBar -bool true

echo "Setting hidden dock applications as translucent"
defaults write com.apple.dock showhidden -bool true

echo "Setting Notification Center banner display time"
defaults write com.apple.notificationcenterui bannerTime 2.5

echo "Disabling autocorrect"
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

echo "Disable natural scroll"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# ensure changes take effect immediately
killall Dock
killall Finder
killall SystemUIServer
