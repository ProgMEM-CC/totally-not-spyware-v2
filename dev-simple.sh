#!/bin/bash

echo "🚀 Simple Dev Mode - Live Editing"
echo "=================================="
echo "This script will:"
echo "1. Start a live server"
echo "2. Show you how to make live changes"
echo "3. Provide commands to sync changes"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

echo "📊 Current git status:"
git status --porcelain

echo ""
echo "🌐 Starting development server..."
echo "Your PWA will be available at: http://localhost:8000"
echo ""
echo "💡 To make live changes:"
echo "1. Open your browser to http://localhost:8000"
echo "2. Open DevTools (F12 or Ctrl+Shift+I)"
echo "3. Make changes in the Elements/Console tab"
echo "4. Copy your changes to the actual files"
echo "5. Run: ./sync-changes.sh"
echo ""

# Start Python HTTP server
python3 -m http.server 8000
