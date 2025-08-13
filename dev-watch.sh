#!/bin/bash

echo "🚀 Development Mode - Live Changes Auto-Sync"
echo "============================================="
echo "This script will:"
echo "1. Start a live server with auto-reload"
echo "2. Watch for file changes and auto-commit"
echo "3. Push changes to GitHub automatically"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check git status
echo "📊 Current git status:"
git status --porcelain

echo ""
echo "🔄 Starting development server..."
echo "🌐 Your PWA will be available at: http://localhost:8000"
echo "📱 Test on mobile: http://localhost:8000"
echo ""

# Function to auto-commit changes
auto_commit() {
    local changed_files=$(git status --porcelain | wc -l)
    if [ $changed_files -gt 0 ]; then
        echo "📝 Auto-committing changes..."
        git add .
        git commit -m "Live dev changes - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "✅ Changes committed!"
        
        echo "🚀 Pushing to GitHub..."
        git push origin main
        echo "✅ Changes pushed to GitHub!"
    fi
}

# Start file watcher in background
echo "👀 Watching for file changes..."
(
    while true; do
        # Watch for changes in key directories
        inotifywait -r -e modify,create,delete,move \
            --exclude '\.git|node_modules|\.DS_Store' \
            . 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "🔄 File change detected!"
            sleep 2  # Wait a bit for file to finish writing
            auto_commit
        fi
    done
) &

WATCHER_PID=$!

# Start Python HTTP server
echo "🌐 Starting HTTP server..."
python3 -m http.server 8000

# Cleanup on exit
trap "echo '🛑 Shutting down...'; kill $WATCHER_PID 2>/dev/null; exit" INT TERM
