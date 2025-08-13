#!/bin/bash

echo "🚀 Auto-Port Development Server - Always Fresh Content"
echo "====================================================="
echo ""

# Function to find an available port
find_available_port() {
    local start_port=${1:-3000}
    local end_port=${2:-9000}
    
    for port in $(seq $start_port $end_port); do
        if ! nc -z localhost $port 2>/dev/null; then
            echo $port
            return 0
        fi
    done
    return 1
}

# Function to stop any existing servers on common ports
stop_existing_servers() {
    echo "🔄 Stopping any existing servers..."
    
    local common_ports=(8000 8080 3000 4000 5000 6000 7000)
    
    for port in "${common_ports[@]}"; do
        # Find Python processes listening on this port
        local pids=$(lsof -ti:$port 2>/dev/null | grep -E "$(pgrep -f 'python.*http.server')" 2>/dev/null)
        
        if [ ! -z "$pids" ]; then
            echo "🛑 Stopping server on port $port (PIDs: $pids)"
            echo "$pids" | xargs kill -9 2>/dev/null
        fi
    done
    
    # Wait a moment for processes to stop
    sleep 2
    echo "✅ Server cleanup complete"
    echo ""
}

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Stop existing servers
stop_existing_servers

# Find an available port
echo "🔍 Finding available port..."
port=$(find_available_port)

if [ -z "$port" ]; then
    echo "❌ Error: No available ports found in range 3000-9000"
    exit 1
fi

echo "✅ Found available port: $port"
echo ""

# Check git status
echo "📊 Checking git status..."
git status

echo ""
echo "🌐 Starting development server..."
echo "Your PWA will be available at: http://localhost:$port"
echo ""

echo "💡 AUTO-PORT REFRESH SYSTEM:"
echo "============================="
echo "• Every time you run this script, it will use a NEW port"
echo "• This ensures you always see the latest changes"
echo "• No more manual port switching needed!"
echo ""

echo "💡 HOW TO MAKE LIVE CHANGES (Desktop Browser):"
echo "1. Open your browser to http://localhost:$port"
echo "2. Open DevTools (F12 or Ctrl+Shift+I)"
echo "3. In Elements tab: Right-click elements to edit HTML/CSS"
echo "4. In Console tab: Test JavaScript changes"
echo "5. In Sources tab: Edit files directly (changes are temporary)"
echo ""

echo "📱 MOBILE DEVICE TESTING:"
echo "========================="
echo "🍎 iPhone Safari: http://localhost:$port"
echo "🤖 Android Chrome: http://localhost:$port"
echo ""

echo "🔄 TO REFRESH AND SEE NEW CHANGES:"
echo "1. Stop this server (Ctrl+C)"
echo "2. Run this script again: ./dev-auto-port.sh"
echo "3. It will automatically use a NEW port"
echo "4. Open the new URL in your browser"
echo ""

echo "📝 When ready to save changes:"
echo "- Copy your changes from DevTools to the actual files in your project directory."
echo "- Run: git add . && git commit -m \"Your message\" && git push origin main"
echo ""

echo "🚀 Starting server on port $port..."
echo "🌐 URL: http://localhost:$port"
echo "🔄 To refresh: Stop server (Ctrl+C) and run this script again"
echo ""

# Start the server
if command -v python3 &> /dev/null; then
    python3 -m http.server $port
elif command -v python &> /dev/null; then
    python -m http.server $port
else
    echo "❌ No Python found. Please install Python."
    read -p "Press Enter to exit"
    exit 1
fi
