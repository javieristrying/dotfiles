#!/usr/bin/env bash
# macOS defaults that used to live in configuration.nix.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "macos.sh is macOS only, skipping"
  exit 0
fi

defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.dock autohide -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder CreateDesktop -bool false
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' >/dev/null

echo "==> macOS defaults written"
