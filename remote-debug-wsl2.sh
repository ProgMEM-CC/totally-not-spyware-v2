#!/bin/bash

echo "🔗 Remote Debugging - iPhone Safari to WSL2/Linux"
echo "=================================================="
echo ""

echo "📱 iPhone Setup:"
echo "1. Connect iPhone to PC via USB cable"
echo "2. On iPhone: Trust this computer (if prompted)"
echo "3. Go to Settings → Safari → Advanced"
echo "4. Enable 'Web Inspector'"
echo "5. Make sure iPhone is unlocked"
echo ""

echo "💻 WSL2/Linux Setup:"
echo "1. Make sure ngrok is installed in WSL2"
echo "2. Install Chrome/Edge on Windows (for DevTools)"
echo "3. No iTunes needed - WSL2 handles drivers"
echo ""

echo "🌐 Starting ngrok tunnel..."
echo "This will give you a public URL for your iPhone"
echo ""

echo "📋 After ngrok starts:"
echo "1. Copy the ngrok URL (e.g., https://abc123.ngrok.io)"
echo "2. Open Safari on iPhone and go to that URL"
echo "3. On Windows, open Chrome/Edge and go to:"
echo "   chrome://inspect/#devices"
echo "4. Your iPhone should appear under 'Remote Target'"
echo "5. Click 'inspect' on your iPhone's Safari tab"
echo "6. You'll see iPhone Safari in a new DevTools window!"
echo ""

echo "💡 WSL2 Benefits:"
echo "- Native Linux tools and performance"
echo "- Better network handling than Windows"
echo "- Easier package management"
echo "- Works with your existing dev workflow"
echo ""

echo "🚀 Starting ngrok..."
echo "Keep this terminal open while debugging!"
echo ""

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok not found. Installing..."
    if command -v snap &> /dev/null; then
        sudo snap install ngrok
    elif command -v apt &> /dev/null; then
        wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
        tar -xzf ngrok-v3-stable-linux-amd64.tgz
        sudo mv ngrok /usr/local/bin/
        rm ngrok-v3-stable-linux-amd64.tgz
    else
        echo "❌ Package manager not supported. Please install ngrok manually."
        echo "Download from: https://ngrok.com/download"
        exit 1
    fi
fi

# Start ngrok
ngrok http 8000
