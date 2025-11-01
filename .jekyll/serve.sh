#!/bin/bash

# Script to test the Jekyll site locally

set -e

./prepare-content.sh

echo "📦 Installing dependencies..."
bundle install

echo "🚀 Starting Jekyll server..."
echo "Site will be available at: http://localhost:4000"
echo "Press Ctrl+C to stop"
bundle exec jekyll serve --baseurl ""
