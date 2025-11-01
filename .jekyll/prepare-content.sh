#!/bin/bash

# Shared script to prepare content for Jekyll

echo "📋 Copying guide.md to index.md with frontmatter..."
{
  echo "---"
  echo "layout: default"
  echo "---"
  echo ""
  cat ../guide.md | sed 's/<details>/<details markdown="1">/g'
} > index.md

echo "🎨 Generating syntax highlighting CSS..."
bundle exec rougify style github.light > assets/css/syntax.css
