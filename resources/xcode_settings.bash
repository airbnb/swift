#!/bin/bash

set -e

defaults write com.apple.dt.Xcode AutomaticallyCheckSpellingWhileTyping -bool YES

defaults write com.apple.dt.Xcode DVTTextEditorTrimTrailingWhitespace -bool YES
defaults write com.apple.dt.Xcode DVTTextEditorTrimWhitespaceOnlyLines -bool YES

defaults write com.apple.dt.Xcode DVTTextPageGuideLocation -int 120
