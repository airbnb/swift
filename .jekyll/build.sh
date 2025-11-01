#!/bin/bash

# Script to build the Jekyll site

set -e

./prepare-content.sh

echo "📦 Installing dependencies..."
bundle install

echo "🔨 Building Jekyll site..."
bundle exec jekyll build --destination ../_site

echo "✅ Build complete! Output in _site/"
