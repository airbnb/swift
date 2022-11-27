#!/bin/bash

if which swiftformat >/dev/null; then
  scripts/git-format-staged.py --formatter "swiftformat --exclude Package.swift stdin --stdinpath '{}'" '*.swift'
else
  echo 'warning: swiftformat not installed, run `bundle install`.'
fi
