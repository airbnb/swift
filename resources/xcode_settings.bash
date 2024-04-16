#!/bin/bash

set -e

defaults write com.apple.dt.Xcode AutomaticallyCheckSpellingWhileTyping -bool YES

defaults write com.apple.dt.Xcode DVTTextEditorTrimTrailingWhitespace -bool YES
defaults write com.apple.dt.Xcode DVTTextEditorTrimWhitespaceOnlyLines -bool YES

defaults write com.apple.dt.Xcode DVTTextIndentTabWidth -int 4
defaults write com.apple.dt.Xcode DVTTextIndentWidth -int 4

defaults write com.apple.dt.Xcode DVTTextPageGuideLocation -int 100
