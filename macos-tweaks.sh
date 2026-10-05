# only open apps in the dock
defaults write com.apple.dock static-only -bool true

# autohide dock
defaults write com.apple.dock autohide -bool true

# dock to the left
defaults write com.apple.dock orientation -string "left"

# faster dock showing and hiding
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0

killall Dock

defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticInlinePredictionEnabled -bool false
defaults write -g NSAutomaticTextCompletionEnabled -bool false

# Turn off the display after 5 minutes of inactivity:
sudo pmset -b displaysleep 5

# Put the Mac to sleep completely after 10 minutes:
sudo pmset -b sleep 15

# This stops your Mac from briefly waking up to check emails, sync iCloud, or run Time Machine backups while asleep on battery
sudo pmset -b powernap 0
